---
name: financial-planner
description: Baut eine nachvollziehbare Liquiditätsplanung aus Stripe/PayPal-Connectoren, losen Belegen und einer expliziten Fixkosten-Liste. Das Modell ist bewusst einfach: Anker ist das Geld von HEUTE (Bank manuell, Stripe/PayPal live), die Zukunft wird davon vorwärts gerechnet (Fixkosten, geplante Posten, wiederkehrende Einnahmen), die Vergangenheit zeigt nur Flüsse ohne Saldo-Anspruch. Haupt-Kennzahl: der Monat, in dem das Geld eng wird (Cash-out). Schreibt financial-planning.md als Text-Wahrheit fort, rendert auswertung.xlsx und dashboard.html als Ansichten, protokolliert jeden Lauf im CHANGELOG. Jede Zahl führt auf eine Quelle oder eine benannte Annahme zurück. Kann zwischendurch auch nur einen künftigen Posten vormerken (Quick-Capture), ohne vollen Lauf. Nutze diesen Skill, wenn im aktuellen Projekt ein finanzplanung/-Ordner liegt und der User sagt "bau die nächste Iteration der Liquiditätsplanung", "aktualisiere die Liquidität", "wie ist mein Cash", "wie lange reicht das Geld", "finanzplanung", oder einen künftigen Posten vormerken will ("merk dir: in 3 Wochen kommt eine Rechnung über 300 Euro").
when_to_use: |
  Trigger-Phrasen voller Lauf: "bau die nächste Iteration der Liquiditätsplanung", "aktualisiere die Liquidität", "lies die Quellen in finanzplanung/ ein", "wie ist mein Cash", "wie lange reicht das Geld", "wann wird es eng", "finanzplanung", "financial-planner". Trigger-Phrasen Quick-Capture (nur vormerken, kein Lauf): "merk dir: in X Wochen kommt eine Rechnung über Y", "vormerken: ...", "plane ein: ...", "da kommt noch eine Zahlung auf uns zu". Voraussetzung: im aktuellen Projekt existiert ein finanzplanung/-Ordner (aus dem Bundle-vorlage/). Nicht triggern für allgemeine Steuer-/Buchhaltungsfragen ohne diesen Ordner.
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion, Bash(ls:*), Bash(mkdir:*), Bash(mv:*), Bash(python3:*), Bash(pip3:*), mcp__claude_ai_Stripe__stripe_api_read, mcp__claude_ai_Stripe__search_stripe_resources, mcp__claude_ai_Stripe__fetch_stripe_resources, mcp__claude_ai_Stripe__get_stripe_account_info, mcp__claude_ai_PayPal__list_transactions, mcp__claude_ai_PayPal__list_invoices
---

# Liquiditätsplanung bauen

Du baust eine **reine Liquiditätsplanung** nach einem bewusst einfachen Modell:

> **Cash heute (live) minus das, was laut Verträgen und Terminen noch kommt, plus das, was laufend reinkommt, ergibt den Monat, in dem es eng wird.**

Drei Bausteine, keine mehr:

1. **Der Anker: Cash heute.** Bank-Kontostand (manuell gepflegt, das Konto ist nicht angebunden) plus Stripe-Saldo (live) plus PayPal-Saldo (live). Das ist die einzige harte, überprüfbare Zahl. Sie wird bei jedem Lauf frisch gezogen bzw. bestätigt.
2. **Die Zukunft: vorwärts vom Anker.** Fixkosten (Verträge), geplante Einmalposten (terminierte Rechnungen, Kapital-Tranchen) und wiederkehrende Einnahmen ergeben eine verkettete Saldo-Vorschau. Erster Monat unter null = Cash-out-Monat, die Haupt-Kennzahl.
3. **Die Vergangenheit: nur Flüsse, kein Saldo.** Die letzten Monate zeigen, was pro Monat reinkam und rausging (Kontext + Basis für die Einnahmen-Fortschreibung). Es gibt bewusst KEINE rückwirkende Saldo-Kette: die Kostenseite ist strukturell unvollständig (Bank nicht angebunden), eine nachgerechnete Historie würde garantiert vom echten Konto abweichen und Vertrauen zerstören. Was passiert ist, steckt bereits im heutigen Kontostand.

Bewusst NICHT in dieser Version: EBIT/Ergebnisrechnung, Umsatzabgrenzung, Steuerrücklagen, USt-Zahllast, historische Saldo-Rekonstruktion, Abgleich "rechnerisches Heute vs. Live-Heute". Es geht nur um Cash: wie viel ist da, wie lange reicht es.

Das Leitprinzip steht in `finanzplanung/CLAUDE.md` und gilt absolut: **die Wahrheit ist Text (`financial-planning.md`), Excel und Dashboard sind nur Ansichten.** Jede Zahl führt auf eine Quelle oder eine benannte Annahme zurück. Du rechnest nie still, du rätst nie eine Kategorie, du erfindest keine fehlende Zahl. Kannst du einen Posten nicht zuordnen, fragst du den User, statt zu raten.

## 0. Orientierung (immer zuerst)

1. Finde das Arbeitsverzeichnis: den Ordner `finanzplanung/` im aktuellen Projekt (er entstand aus `vorlage/`). Alle Pfade unten sind relativ dazu.
2. Lies in dieser Reihenfolge, ohne sie zu duplizieren:
   - `CLAUDE.md`: die Regeln beim Rechnen (PFLICHT).
   - `ANNAHMEN.md`: Konfiguration (Bank-Kontostand + Stand-Datum, Währung), **Fixkosten-Tabelle**, **Geplante Posten**, aktive Annahmen.
   - `SOURCES.md`: welche Quelle `aktiv` ist und über welchen Kanal sie liefert.
   - `KOSTEN-KATEGORIEN.md`: die gültigen Kostenblöcke und Zuordnungs-Regeln.
   - `financial-planning.md` + `CHANGELOG.md`: den bisherigen Stand (bei Folgeläufen der Ausgangspunkt fürs Diff).
3. Bestimme die Betriebsart (Schritt 1) und bei vollem Lauf die nächste Iterationsnummer aus dem `CHANGELOG.md`.

## 1. Betriebsart: Quick-Capture oder voller Lauf

**Quick-Capture** greift, wenn der User nur einen künftigen Posten vormerken will ("in 3 Wochen kommt eine Rechnung über 300 Euro", "im September kommt die zweite Tranche"). Dann:

1. Extrahiere Datum (relatives "in 3 Wochen" in ein konkretes Datum auflösen), Betrag, Richtung (`ein`/`aus`), Beschreibung. Bei Abflüssen den Kostenblock aus `KOSTEN-KATEGORIEN.md` zuordnen, wenn eindeutig; sonst kurz nachfragen.
2. Trage GENAU EINE Zeile in `ANNAHMEN.md` unter `## Geplante Posten` ein, Status `offen`.
3. Bestätige dem User die Zeile im Klartext ("Vorgemerkt: 21.08. Abfluss 300 Euro, Agentur-Rechnung, Kostenblock fremdleistungen"). ENDE. Kein Connector-Zug, keine Excel, kein CHANGELOG-Eintrag (die Zeile selbst ist der Diff).

Ein wiederkehrender Posten ("ab sofort 89 Euro monatlich für Tool X") gehört stattdessen in die **Fixkosten-Tabelle**, gleiche Mechanik.

Alles andere ist ein **voller Lauf** (Schritte 2 bis 7).

### Anker-Frage zu Beginn jedes vollen Laufs (PFLICHT)

Bevor du Quellen ziehst, frag den User nach der einen Zahl, die er selbst pflegen muss:

> "Wie viel liegt heute insgesamt auf dem Bankkonto (und anderen nicht angebundenen Konten)? Stripe und PayPal ziehe ich gleich automatisch."

Biete dabei den letzten bekannten Wert als Schnell-Bestätigung an (z.B. "unverändert: 12.000,00, Stand 10.07."), damit die Antwort im Normalfall ein Klick ist. Neuen Wert + heutiges `stand_datum` nach `ANNAHMEN.md` schreiben. Diese Frage kommt bewusst IMMER am Anfang: der ganze Forecast hängt an dieser Zahl, und eine Stale-Heuristik braucht es so nicht. Beim allerersten Lauf ist sie Teil des First-Run-Onboardings (gebündelt mit den anderen Fragen, nicht doppelt stellen).

### First-Run-Onboarding (nur wenn Config unvollständig)

Prüfe den Konfigurations-Block in `ANNAHMEN.md`. Ist er unvollständig (typisch beim allerersten Lauf), stelle die offenen Fragen **einmal gebündelt** via `AskUserQuestion`:

- **Bank-Cash JETZT**: der tatsächliche aktuelle Stand des Bankkontos plus etwaiger weiterer nicht angebundener Konten (Zweitkonto, Sparkonto, Kasse), als EINE Summe, plus heutiges Datum als `stand_datum`. Diese Konten sind nicht angebunden, deshalb pflegt der User den Wert selbst; Hinweis dazu: Stripe und PayPal werden automatisch live gezogen. Alles, was je passiert ist (auch erhaltene Investment-Tranchen), steckt in dieser Zahl bereits drin.
- **Währung**: Standard `EUR`.
- **Fixkosten (Verträge)**: die laufenden, regelmäßigen Zahlungen (Gehälter, Miete, Hosting/SaaS, Steuerberater, Versicherungen) mit Betrag, Rhythmus und nächster Fälligkeit. Das wird die initiale Fixkosten-Tabelle. Lieber grob vollständig als perfekt: der Skill schlägt später Ergänzungen vor, wenn er Wiederkehrendes in den Quellen sieht.
- **Schon bekannte künftige Einmalposten**: terminierte Rechnungen, angekündigte Kapital-Tranchen. Landen als Geplante Posten.

Schreibe die Antworten nach `ANNAHMEN.md` (Konfigurations-Block, Fixkosten-Tabelle, Geplante Posten) und entferne beantwortete Punkte aus `## Offene Fragen`. Bei späteren Läufen ist die Config gefüllt, dann nur noch den Bank-Kontostand bestätigen (Schritt 4).

## 2. Datenmodell (pro Ist-Buchung)

Das Buchungsjournal enthält NUR echte Buchungen (Ist). Forecast-Positionen entstehen aus `ANNAHMEN.md` (Fixkosten, Geplante Posten) plus Fortschreibung und stehen in der Forecast-Matrix mit Herkunft, nicht als Pseudo-Buchungen im Journal.

- `id`: die Quell-Transaktions-ID (Stripe charge id, PayPal transaction_id; bei Belegen ein stabiler Schlüssel aus Datei + Datum + Betrag). **Der Dedup-Schlüssel für wiederholte Läufe.**
- `date`: der Tag, an dem das Geld tatsächlich fließt (Cash-Datum).
- `direction`: `ein` oder `aus`.
- `gross`, `fee`, `net`, `currency`.
- `stream` (bei Einnahmen: `stripe`, `paypal`) bzw. `category` (bei Ausgaben: Kostenblock-Slug aus `KOSTEN-KATEGORIEN.md`).
- `description`: Gegenpartei/Zweck in Klartext.
- `source`: `stripe`/`paypal`/`beleg`.
- `confidence`: nur bei Belegen.
- `status`: `ist` (verbucht) oder `offen` (unklarer Posten, wartet auf Rückfrage).

## 3. Ingestion pro Quelle

Arbeite nur Quellen mit Status `aktiv` aus `SOURCES.md` ab. **Fenster-Default: die letzten 3 vollen Monate plus der laufende Monat** (mehr Vergangenheit bringt der Planung nichts und kostet nur API-Calls; der User kann explizit mehr verlangen).

### Stripe (Connector, aktiv)

- `stripe_api_read` auf `GetCharges` mit `expand: ["data.balance_transaction"]`, paginiert über `starting_after`, gefiltert `created >=` Fensterstart. Pro Charge:
  - `gross` = `charge.amount`, `fee` = `balance_transaction.fee`, `net` = `balance_transaction.net` (Minor Units, durch 100 teilen).
  - `date` = `balance_transaction.available_on` (wann das Geld auszahlbar wird).
  - Die Zahlung als **Einnahme** (`stream: stripe`, `gross`), die Gebühr als Kostenblock `finanzgebuehren`.
  - Refunds: `charge.amount_refunded` als negative Einnahme gegenrechnen.
- `stripe_api_read` auf `GetBalance`: aktueller Stripe-Saldo (available) für den Anker.
- Hinweis: die dedizierten `GetPayouts`/`GetBalanceTransactions` sind gesperrt; der `expand`-Umweg liefert die Gebühren trotzdem. Kein Datei-Export nötig.

### PayPal (Connector, aktiv)

- `list_transactions` in **31-Tage-Fenstern** geloopt, bis das Fenster abgedeckt ist.
- PayPal-Saldo aus `ending_balance`/`available_balance` für den Anker.
- T-Code-Mapping:
  - `T0006` = Einnahme (`stream: paypal`).
  - `T0111` = Refund (negative Einnahme).
  - `T2002` = Inter-Account-Transfer (Umbuchung PayPal zu Bank): weder Einnahme noch Ausgabe, komplett neutral behandeln. Der Gesamt-Cash ändert sich nicht, nur der Topf.
  - `T0003` (beobachtet 2026-07): vorab genehmigte Zahlung/Abo, also ein Abfluss. Kostenblock trotzdem erfragen, nicht raten.
  - `T0011` (beobachtet 2026-07): Zuordnung unklar, immer erfragen.
- **Nicht zuordenbare Posten: interaktiv fragen (PFLICHT).** Unbekannter T-Code oder unklare Richtung: sammeln und gebündelt via `AskUserQuestion` vorlegen (Betrag, Datum, Gegenpartei, T-Code). Erst nach Antwort verbuchen; ohne Antwort bleibt der Posten `offen` und fließt NICHT still in eine Kategorie.
- **Auth-Ablauf abfangen (beobachtet 2026-07: `401 Unauthorized` nach Token-Ablauf).** Liefert ein Connector 401/Auth-Fehler: NICHT abbrechen und nichts erfinden. Dem User sagen, dass der Connector in claude.ai neu verbunden werden muss (danach Claude Code neu starten), den Lauf mit den vorhandenen Journal-Daten fortsetzen und die Quelle im Report als "diese Iteration nicht erreichbar, Stand vom letzten Lauf" ausweisen. Gleiches Muster wie bei `geplant`-Quellen: Lücke benennen statt Fehler werfen.

### Belege (`belege/_neu/`): immer verarbeiten

- Jede Datei lesen (PDF/Foto/CSV/Screenshot), `gross`/Datum/Empfänger extrahieren, als Ausgabe erfassen.
- Gegen `KOSTEN-KATEGORIEN.md` kategorisieren. **Confidence < 0.85 = `uncategorized`**, in die "zu prüfen"-Queue, nicht raten.
- Nach Verarbeitung mit `YYYY-MM-DD-<kategorie>-`-Präfix nach `belege/analysiert/` verschieben (`mv`).

### Datei-Quellen (sevDesk/Pliant/Bank): nur wenn `aktiv`

- `exporte/<slug>/_neu/` lesen. **Schema NICHT raten:** unbekannter Spaltenaufbau = stoppen und nach echtem Export/Schema fragen.
- Nach Verarbeitung mit `YYYY-MM-DD-`-Präfix nach `analysiert/` verschieben.
- `geplant`-Quellen überspringen und am Ende als Lücke melden (kein Fehler).
- Offene sevDesk-Rechnungen (Zahlstatus `offen` + Fälligkeit) werden NICHT ins Journal gebucht, sondern als **Geplante Posten** in `ANNAHMEN.md` vorgeschlagen (das ist "was noch abgebucht wird").

## 4. Wiederhol-Lauf (rollierend, typisch wöchentlich)

- **Ist-Buchungen über `id` abgleichen.** Jede gezogene Buchung gegen das Journal: `id` bekannt und unverändert = nichts tun; `id` bekannt, Werte geändert (z.B. nachträgliche Erstattung) = Zeile aktualisieren; `id` neu = aufnehmen. Überlappende Fenster sind dadurch gewollt unkritisch.
- **Belege/Datei-Exporte akkumulieren über die Ordnerlogik** (`_neu/` wird verarbeitet und nach `analysiert/` verschoben, nie zweimal gelesen).
- **Anker-Refresh.** Stripe/PayPal-Salden live ziehen. Der Bank-Cash-Wert kommt aus der Anker-Frage zu Laufbeginn (siehe Schritt 1); einen vom User von Hand (z.B. direkt in `ANNAHMEN.md` oder der gelben Excel-Zelle) geänderten Wert nie still überschreiben, sondern in der Anker-Frage als letzten bekannten Wert anbieten.
- **Geplante Posten abgleichen (Lifecycle).** Für jeden Posten mit Status `offen` und Datum in der Vergangenheit:
  - Passt eine echte Journal-Buchung dazu (Betrag ähnlich, Zeitraum nah, Gegenpartei plausibel): Status auf `erledigt` setzen mit Verweis auf die Buchungs-`id`. Der Posten verschwindet aus dem Forecast, die echte Buchung ist ja da. **Nie beides zählen.**
  - Passt nichts: via `AskUserQuestion` klären (kommt noch: Datum verschieben / kommt nicht mehr: streichen / lief übers Bankkonto und ist im Kontostand: erledigt ohne Buchungs-Verweis). Nie still verfallen lassen.
- **Fixkosten werden NICHT gematcht, nur fortgeschrieben.** Sie laufen typisch übers nicht angebundene Bankkonto und sind als Einzelbuchung unsichtbar; ihre Vergangenheit steckt im bestätigten Bank-Kontostand. Nach Ablauf einer Fälligkeit rückt `nächste Fälligkeit` einen Rhythmus weiter. Sieht der Skill in den Quellen einen wiederkehrenden Posten, der NICHT in der Tabelle steht, schlägt er die Aufnahme vor (nie eigenmächtig eintragen).

## 5. financial-planning.md fortschreiben (die Wahrheit)

Schreibe `financial-planning.md` mit dieser Struktur; jede Kennzahl bekommt ihre Herkunft:

1. **Stand**: Datum des Laufs, Ingestion-Fenster, und die **Anker-Zerlegung**: Bank-Kontostand (mit `stand_datum`) + Stripe available + PayPal-Saldo = **Cash heute**.
2. **Cockpit**:
   - **Cash heute** (der Anker).
   - **Cash-out-Monat**: erster Forecast-Monat mit Endsaldo < 0, oder "reicht über den Planungshorizont hinaus". Das ist DIE Kennzahl.
   - **Einnahmen und Ausgaben des letzten vollen Monats** (aus der Fluss-Matrix).
   - **Offene Posten** (Anzahl + Summe der "zu prüfen"-Queue). Alert, wenn > 2 % des Transaktionsvolumens.
3. **Vergangenheit (Fluss-Matrix)**: die letzten 3 vollen Monate + laufender Monat bisher. Je Einnahmestrom und je Kostenblock eine Zeile, dazu Netto-Cashflow je Monat. **Bewusst KEINE Anfangs-/Endsaldo-Zeilen** (siehe Modell oben). Mit Hinweis: zeigt nur die angebundenen Quellen, nicht das komplette Konto.
4. **Forecast (Saldo-Kette ab heute)**: Rest des laufenden Monats + 6 Folgemonate. Je Monat:
   - Wiederkehrende Einnahmen je Strom: Fortschreibung = Durchschnitt der letzten 3 vollen Monate, **ab dem Folgemonat** (Herkunft `fortschreibung`; per Annahme-Zeile überschreibbar).
   - Geplante Zuflüsse (Kapital-Tranchen etc.) auf ihr Datum (Herkunft `geplant`).
   - Fixkosten je Rhythmus auf ihre Fälligkeit (Herkunft `fixkosten`).
   - Geplante Abflüsse auf ihr Datum (Herkunft `geplant`).
   - Netto und **Endsaldo verkettet**: Startpunkt Cash heute, Endsaldo = Vormonat + Netto.
   - **Konservativ-Regel laufender Monat:** für den Rest des laufenden Monats zählen nur terminierte Posten und noch fällige Fixkosten, KEINE anteilige Einnahmen-Fortschreibung (schon eingegangene Einnahmen stecken im Anker; lieber vorsichtig als doppelt).
5. **Buchungsjournal**: jede Ist-Buchung eine Zeile (`id`, `date`, `source`, `direction`, `stream`/`category`, `description`, `gross`/`fee`/`net`, `status`). Der Drill-down unter der Fluss-Matrix und die Dedup-Grundlage für Schritt 4.
6. **Zu prüfen**: die Zeilen mit `status: offen` (uncategorized-Belege, unklare PayPal-Posten) plus überfällige Geplante Posten ohne Klärung.

## 6. Ansichten rendern

Beide Ansichten werden bei jedem Lauf **komplett neu erzeugt** (nie manuell editieren). Python/`openpyxl` für die Excel; fehlt `openpyxl`, sag es dem User (`pip3 install openpyxl`).

### auswertung.xlsx

| Tab | Inhalt |
|---|---|
| `00_Cockpit` | Cash heute (Anker-Zerlegung mit der gelben Bank-Zelle), Cash-out-Monat, Einnahmen/Ausgaben letzter voller Monat, offene Posten. Per Formel auf `01_Liquiditaet` referenziert |
| `01_Liquiditaet` | Zweigeteilt. **Links die Vergangenheit** (letzte 3 volle Monate + laufender Monat bisher): nur Flusszeilen, grau hinterlegt, KEINE Saldozeilen. **Dann der Anker-Block**: Bank-Kontostand als **gelbe manuelle Eingabezelle**, Stripe/PayPal-Salden, Cash heute als Formel (= Summe der drei). **Rechts der Forecast** (Rest-Monat + 6 Monate): Einnahmen-, Fixkosten-, Geplante-Posten-Zeilen, Netto, **Endsaldo als verkettete Formel** ab der Cash-heute-Zelle. Ändert der User die gelbe Zelle, rechnet sich die ganze Vorschau neu, ohne dass der Skill läuft |
| `02_Buchungen` | das vollständige Ist-Journal, eine Zeile pro Buchung, AutoFilter; `offen`-Zeilen farblich markiert (die "zu prüfen"-Liste) |

- Nur Ist-Werte und die gelbe Bank-Zelle sind statisch; **jede abgeleitete Zelle ist eine echte Excel-Formel** (Summen, Netto, Saldo-Kette, Cockpit-Referenzen).
- Den **ersten Forecast-Monat mit negativem Endsaldo rot hervorheben** (beim Rendern prüfen und einfärben): das ist der sichtbare Cash-out.

### dashboard.html

Eine self-contained HTML-Datei im selben Ordner, als dritte Ansicht derselben Monatsmatrix. **Komplett offline: Inline-CSS, Inline-JS, Diagramme als hand-gerolltes SVG. KEINE externen Ressourcen, kein CDN** (Finanzdaten bleiben lokal, die Datei muss ohne Netz im Browser aufgehen).

Inhalt:
- **Cash-heute-Kachel** groß, mit der Anker-Zerlegung (Bank + Stripe + PayPal) und dem Stand-Datum der Bank-Zahl.
- **Saldo-Verlauf des Forecasts** (Linie oder Balken über die nächsten Monate), Cash-out-Monat rot markiert, Null-Linie sichtbar.
- **Vergangenheit als Ein/Aus-Balkenpaare** je Monat (die letzten 3 vollen Monate).
- **Fixkosten-Liste** (was jeden Monat sicher rausgeht) und **Geplante Posten** (was terminiert noch kommt), je mit Summen.
- **Offene Posten** als Hinweisblock, falls vorhanden.

## 7. Abschluss jedes Laufs

1. **CHANGELOG.md** fortschreiben (eine Sektion pro Lauf, Format aus der Datei): gelesene Quellen + Zeilen, was sich geändert hat, neue/geänderte Annahmen und Geplante Posten, offene Lücken.
2. Verarbeitete Datei-Exporte + Belege nach `analysiert/` verschieben (siehe Schritt 3).
3. Dem User einen **kompakten Report** geben: Cash heute, **Cash-out-Monat prominent**, die größten Bewegungen zum Vorlauf, überfällige Geplante Posten und "zu prüfen"-Rückfragen, welche `geplant`-Quellen noch fehlen. Keinen Excel-Dump im Chat.
4. Nicht ungefragt committen: das stößt der User bewusst nach Diff-Prüfung an (siehe README Schritt 4, "sichere diese Iteration als Version"). Wenn er das tut: Änderungen in Alltagssprache zusammenfassen, dann committen. Existiert im Projekt noch kein Git-Repo, einmalig anbieten, es einzurichten (`git init` + erster Commit), damit die Versionierung ab Iteration 1 greift.

## Später erweiterbar (bewusst NICHT in dieser Version)

Ergebnis/EBIT (accrual, zweites Datum), Umsatzabgrenzung für Jahres-Abos, Steuerrücklage, Szenarien ("was, wenn die Tranche nicht kommt": heute manuell über die gelbe Zelle bzw. eine Geplante-Posten-Zeile spielbar). Die getrennte Text-Wahrheit macht das möglich, ohne den Bestand umzubauen.

## Eiserne Regeln (aus CLAUDE.md, hier nochmal)

- Rechne nie still: jede Zahl mit Herkunft (`quelle`, `fixkosten`, `geplant`, `fortschreibung` oder Annahme).
- Der einzige Saldo-Anker ist Cash heute. **Die Vergangenheit bekommt keine Saldo-Kette.**
- Rate nie eine Kategorie: Confidence < 0.85 = `uncategorized` + Rückfrage.
- Rate nie einen PayPal-Posten: unbekannter T-Code oder unklare Richtung = interaktiv fragen.
- Erfinde nie eine fehlende Zahl: offen lassen, als Frage vermerken.
- Rate nie ein Datei-Schema: bei Unbekanntem stoppen und nach echtem Export fragen.
- Geplante Posten nie doppelt zählen (nach Match mit echter Buchung: `erledigt`) und nie still verfallen lassen (überfällig = nachfragen).
- Neue Kostenblöcke und Fixkosten-Zeilen nur nach Bestätigung des Users.
