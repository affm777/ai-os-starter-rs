# Quellen-Manifest

Die eine Stelle, an der steht, aus welchem System welche Daten kommen und in welchem Zustand die Anbindung ist. Der Skill liest diese Datei zuerst, dann arbeitet er die Quellen ab.

**So erweiterst du:** Neue Quelle = neue Zeile hier plus ein Ordner unter `exporte/<slug>/`. Kein Umbau am Skill. Was auf `aktiv` steht und Dateien in `_neu/` hat, wird verarbeitet. Was auf `geplant` steht, wird übersprungen und im Lauf als Lücke gemeldet, nicht als Fehler.

## Zwei Seiten: Einnahmen und Kosten

Eine Finanzplanung braucht beide Seiten. Die System-Quellen unten liefern je nach System Einnahmen, Kosten oder beides. Kosten, die in keinem angebundenen System liegen (typisch: alles vom nicht verbundenen Bankkonto, lose Rechnungen und Belege), kommen über den **Belege-Intake** weiter unten rein.

## Kanäle

Eine Quelle kann auf drei Wegen liefern:

- **datei** — du legst Exporte in `exporte/<slug>/_neu/`, der Skill liest sie und schiebt sie nach `analysiert/`.
- **connector** — der Skill zieht live über einen verbundenen Claude-Connector, kein Ordner nötig.
- **beleg** — du wirfst lose Dateien jeder Form (PDF, Foto, CSV, Screenshot) nach `belege/_neu/`. Der Skill liest jede, ordnet sie einem Kostenblock aus `KOSTEN-KATEGORIEN.md` zu, baut daraus einen Posten und fragt nach, wenn die Zuordnung unklar ist. Siehe Abschnitt „Belege-Intake".

Für Stripe und PayPal reicht der **Connector allein**, kein Export (empirisch geprüft 16.07.). Bei Stripe kommt die Gebühr pro Zahlung über `GetCharges` mit `expand: ["data.balance_transaction"]` inline mit: `fee` (Stripe-Gebühr), `net` (Netto nach Gebühr) und `available_on` (wann das Geld auszahlbar wird). Zusammen mit `GetBalance` (Ist-Saldo) deckt das die Finanzplanung ab. Die dedizierten Tools `GetPayouts`/`GetBalanceTransactions` sind zwar gesperrt, aber der `expand`-Umweg liefert dieselben Zahlen. PayPal liefert über `list_transactions` den laufenden Saldo direkt. Ein Datei-Export ist bei diesen beiden nur für den Randfall „exakte Payout-Batch-zu-Bankkonto-Zuordnung" nötig, den eine Finanzplanung nicht braucht.

## Register: System-Quellen

| Slug | System | Kanal | Seite | Was | Standort-fähig | Status |
|---|---|---|---|---|---|---|
| `stripe` | Stripe | connector | Einnahme | Live und vollständig: Zahlungen mit Gebühr + Netto + Auszahlbar-Datum (`GetCharges` + `expand: data.balance_transaction` → `fee`/`net`/`available_on`), Ist-Saldo (`GetBalance`), Rechnungen (`search_stripe_resources`) | nur wenn Payment Links mit `metadata[standort]` getaggt sind | **aktiv** |
| `paypal` | PayPal | connector | Einnahme | Live: Transaktionen mit laufendem Saldo (`list_transactions`, max. 31-Tage-Fenster pro Abruf), Rechnungen (`list_invoices`). Deckt Zufluss und Saldo komplett ab | nein | **aktiv** |
| `stripe` | Stripe | datei | Einnahme | Optional, nur bei Bedarf: exakte Payout-Batch-zu-Bankkonto-Zuordnung (itemized Payout Reconciliation CSV). Für gross/fee/net NICHT nötig, das kommt per Connector | nur wenn Payment Links mit `metadata[standort]` getaggt sind | geplant (Randfall) |
| `sevdesk` | sevDesk | datei | beide | **Itemized Listenexport** aus der Ausgaben-/Rechnungs-Ansicht (NICHT der DATEV/EXTF-Steuerberater-Export): je Beleg eine Zeile mit Belegdatum, Lieferant/Kunde, Betrag, Zahlstatus, Zahldatum, Kategorie. Schema unten | Kostenstellen nur im Tarif Buchhaltung Pro | geplant (Schema provisorisch, gegen ersten echten Export verifizieren) |
| `pliant` | Pliant | datei | Kosten | Kreditkarten-Transaktionen (CSV), laufende Ausgaben | unbekannt, Spalten nicht dokumentiert | geplant |
| `bank` | Bankkonto | datei | beide | Kontoauszug (CAMT.053 XML oder CSV), alle Zu- und Abflüsse | nur bei getrennten Konten pro Standort | geplant (nicht angebunden, Kosten laufen bis dahin über Belege-Intake) |

## sevDesk-Schema (vorbereitet, provisorisch)

Für die Liquidität nutzen wir den **itemized Listenexport** aus der Ausgaben-/Rechnungs-Ansicht, **nicht** den DATEV-EXTF-Buchungsstapel (der ist buchhalterisch, Soll/Haben auf SKR-Konten, und der Steuerberater-Weg). Die erwarteten Spalten (gegen den ersten echten Export mit Daten zu verifizieren, vorher NICHT scharf schalten, Status bleibt `geplant`):

| sevDesk-Spalte (erwartet) | unser Feld | Hinweis |
|---|---|---|
| Belegnummer | `id` | Dedup-Schlüssel |
| Zahldatum (bei bezahlt) | `date` | der Cash-Zeitpunkt |
| Zahlstatus (bezahlt/offen) | `status` | bezahlt → `ist` (Journal); offen → Vorschlag als **Geplanter Posten** in `ANNAHMEN.md` |
| Fälligkeit (bei offen) | Datum des Geplanten Postens | offene Posten = „was noch abgebucht wird", laufen über die Geplante-Posten-Tabelle |
| Lieferant/Kunde | `description` | Gegenpartei |
| Belegtyp (Ausgangs-/Eingangsrechnung) | `direction` | Ausgang = `ein`, Eingang = `aus` |
| Betrag brutto / netto | `gross` / `net` | |
| Kategorie / Buchungskonto | `category` | → Kostenblock-Mapping aus `KOSTEN-KATEGORIEN.md` |

**Doppelzählung vermeiden:** Zahlungen, die schon über den Stripe- oder PayPal-Connector kommen, NICHT zusätzlich aus sevDesk buchen. sevDesk liefert vor allem die **Kostenseite** (Eingangsrechnungen/Belege), die nicht über die Connectoren läuft.

## Konto-Transfers (nicht doppelt zählen)

Geld zwischen **eigenen** Töpfen (PayPal-Auszahlung aufs Bankkonto, Stripe-Payout) ist weder Einnahme noch Ausgabe, es ändert den Gesamt-Cash nicht. Regel heute: PayPal-`T2002` und Stripe-Payouts komplett neutral behandeln (verifiziert 2026-07-16: naives Mitzählen verfälscht Umsatz, Burn und im Kosten-Fall den Netto-Cash). Eine Matching-Heuristik für Transfer-Paare (Bank-Buchung „PayPal/Übertrag" gegen betrags- und datumsnahe Gegenseite) wird erst gebaut, wenn ein Bank-Export als Quelle dazukommt; vorher gibt es nichts zu matchen.

## Belege-Intake (lose Kosten, `belege/`)

Für Kosten, die in keinem angebundenen System liegen. Das Bankkonto ist nicht verbunden, viele Ausgaben liegen nur als PDF, Foto oder CSV vor. Dafür der Ordner `belege/`:

- Du wirfst Dateien **jeder Form** nach `belege/_neu/`, ohne vorher zu sortieren.
- Der Skill liest jede Datei, extrahiert Betrag, Datum, Empfänger/Zweck und ordnet sie einem **Kostenblock** aus `KOSTEN-KATEGORIEN.md` zu (z.B. G&A, Personal, Tooling, Marketing, Steuern).
- Ist die Zuordnung eindeutig, wird der Posten gebaut und die Datei mit Datums- und Kategorie-Präfix nach `belege/analysiert/` verschoben.
- Ist sie **unklar oder passt in keinen Block**, rät der Skill nicht: er listet die Datei am Ende auf und fragt, welchem Kostenblock sie zugeordnet werden soll (oder ob ein neuer Block in `KOSTEN-KATEGORIEN.md` nötig ist).

Die gültigen Kostenblöcke stehen in `KOSTEN-KATEGORIEN.md`. Diese Taxonomie ist bewusst als eigene Datei ausgelagert, damit sie sich ändern lässt, ohne den Skill anzufassen.

## Regel für den Skill

1. Nur System-Quellen mit Status `aktiv` verarbeiten.
2. Pro aktiver Datei-Quelle: alles in `_neu/` lesen, in die Auswertung einarbeiten, danach mit Datum-Präfix (`YYYY-MM-DD-`) nach `analysiert/` verschieben.
3. Aktive Connector-Quellen live abfragen (kein Ordner). Fenster-Default: die letzten 3 vollen Monate plus laufender Monat (mehr nur auf expliziten Wunsch).
4. `belege/_neu/` immer verarbeiten: jede Datei einem Kostenblock aus `KOSTEN-KATEGORIEN.md` zuordnen, Posten bauen, Datei nach `belege/analysiert/` verschieben. Unklare Zuordnungen nicht raten, sondern am Ende als Rückfrage sammeln.
5. `geplant`-Quellen überspringen und am Ende als Lücke nennen: „sevDesk noch nicht angebunden, Kostenseite dieser Iteration kommt aus Belege-Intake."
6. Nie gegen geratene Spalten oder geratene Kategorien arbeiten. Kennt der Skill das Schema einer Quelle nicht, oder passt ein Beleg in keinen Block, meldet er das und fragt, statt zu raten.
