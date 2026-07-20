# Liquiditätsplanung, die nachvollziehbar bleibt

Deine Finanzdaten liegen in Stripe, PayPal, auf dem Konto und in losen Belegen. Die Liquiditätsplanung, also wann ist welches Geld da, was kommt rein und was geht raus, zieht sich das mühsam zusammen, und am Ende steht eine Zahl, die niemand mehr nachvollziehen kann.

Diese Version macht bewusst nur die eine, wichtigste Sache: **reine Liquidität** nach einem einfachen Anker-Modell. **Cash heute** (Bank manuell, Stripe/PayPal live) minus das, was laut Verträgen und Terminen noch kommt, plus das, was laufend reinkommt, ergibt den **Monat, in dem es eng wird**. Die Vergangenheit zeigt nur, was pro Monat floss, ohne nachgerechneten Kontostand (der würde bei nicht angebundener Bank sowieso vom echten Konto abweichen). Kein EBIT, keine Steuerrücklage, keine Umsatzabgrenzung. Das lässt sich später aufsatteln, ohne den Bestand umzubauen.

Und das Prinzip dahinter: **Die Wahrheit ist Text, Excel und Dashboard sind nur Ansichten.** Jede Zahl führt auf eine benannte Annahme oder eine Quelldatei zurück, jede Änderung ist ein Git-Diff. Das ist mehr Nachvollziehbarkeit als Excel, wo die Annahme unsichtbar in der Formel steckt.

```
exporte/<quelle>/_neu/     Claude                     Ausgabe
──────────────────────     ──────                     ───────
CSV, XLSX reinwerfen   →   /financial-planner    →   financial-planning.md (die Wahrheit)
Connectoren live           liest, rechnet,            auswertung.xlsx       (Ansicht: Excel)
                           dokumentiert               dashboard.html        (Ansicht: Browser)
                                │                     CHANGELOG.md          (der Nachweis)
                                ▼
                           verschiebt Verarbeitetes nach _neu/ → analysiert/
```

## Konventionen in dieser Anleitung

- **„Sag Claude:"** + Block — du tippst das in den **Chat** von Claude Code.
- Der Ordner `vorlage/` ist das leere Gerüst. Es zieht in dein Projekt ein und heißt dort `finanzplanung/`.

## Voraussetzungen

- Standard-Bootstrap (`bash bootstrap.sh`) ist durchgelaufen.
- Python mit `openpyxl` (für den Excel-Render): `pip3 install openpyxl`, falls nicht vorhanden. Claude sagt dir, wenn es fehlt.
- **Stripe- und PayPal-Connector verbunden** (siehe „Connectoren verbinden" unten). **Das ist der wichtigste Schritt.** Über die Connectoren kommen Zahlungen, Gebühren und Saldo live, ein Datei-Export ist dafür nicht nötig.

## Connectoren verbinden (einmal, vor dem ersten Lauf)

Stripe und PayPal liefern alles Nötige live über ihren Claude-Connector (empirisch geprüft), kein Datei-Export:

- **Stripe:** Zahlungen mit Gebühr und Netto (`GetCharges` + `expand: data.balance_transaction` → `fee`/`net`/`available_on`) plus Ist-Saldo (`GetBalance`).
- **PayPal:** Transaktionen mit laufendem Saldo (`list_transactions`, max. 31-Tage-Fenster pro Abruf).

So verbindest du beide:

1. claude.ai → Einstellungen → Connectors → **Stripe** verbinden, dann **PayPal** verbinden.
2. Claude Code neu starten (`/exit`, dann `claude`), damit die Tools in der Session erscheinen.
3. In `SOURCES.md` stehen `stripe · connector` und `paypal · connector` bereits auf `aktiv`.

Die restliche Konfiguration (aktueller Bank-Kontostand, Währung, deine laufenden Verträge als Fixkosten-Tabelle, schon bekannte künftige Posten) fragt der Skill beim ersten Lauf einmal selbst ab und schreibt sie in `ANNAHMEN.md`. Kein separates Setup-Dokument nötig.

Ein Datei-Export ist bei Stripe nur für den Randfall „exakte Payout-Batch-zu-Bankkonto-Zuordnung" nötig, den eine Finanzplanung nicht braucht. Andere Quellen (sevDesk, Pliant, Bank) laufen weiter über Datei-Exporte, siehe „Weitere Quellen anbinden".

## Schritt 1 — Projekt anlegen

```
/new-project
```

Damit hast du CLAUDE.md, STATE.md und einen `.claude/`-Ordner.

## Schritt 2 — Bundle ins Projekt holen

Sag Claude:

```
Lade das Use-Case-Bundle "financial-planner" aus dem Workshop-Repo:
https://github.com/affm777/ai-os-starter-rs/tree/main/claude/use-cases/financial-planner

Platziere es in meinem aktuellen Projekt so:
- vorlage/                  → ./finanzplanung/   (mit allen Unterordnern)
- skills/financial-planner/ → .claude/skills/financial-planner/

Bestätige mir, welche Dateien und Ordner angekommen sind.
```

Danach `/exit` und `claude` neu starten, damit der Skill geladen wird.

## Schritt 3 — Erste Iteration bauen

Stripe- und PayPal-Connector verbunden (siehe „Connectoren verbinden" oben)? Dann sag Claude:

```
Lies die Quellen in finanzplanung/ ein und bau die nächste Iteration
der Finanzplanung.
```

Der Skill `financial-planner` läuft an:
1. liest `SOURCES.md` und `ANNAHMEN.md` (Fixkosten, Geplante Posten),
2. fragt dich ZUERST kurz nach dem **Bank-Cash heute** (Bankkonto plus andere nicht angebundene Konten, eine Summe; letzten Wert bestätigen reicht) und weist darauf hin, dass Stripe und PayPal automatisch geladen werden,
3. zieht Stripe und PayPal live über den Connector (Zahlungen mit Gebühr + Netto, aktuelle Salden), liest alles in `_neu/` der aktiven Datei-Quellen und `belege/_neu/` und bildet den Anker: Cash heute,
4. schreibt `financial-planning.md` fort: Vergangenheit als Fluss-Matrix, Forecast als Saldo-Kette ab heute, **Cash-out-Monat** als Haupt-Kennzahl,
5. rendert `auswertung.xlsx` (drei Tabs: `00_Cockpit`, `01_Liquiditaet` mit gelber Bank-Eingabezelle und verketteter Forecast-Formelkette, `02_Buchungen` als Drill-down) und `dashboard.html` (offline-Browser-Ansicht: Cash-Kachel, Saldo-Verlauf mit Cash-out-Marker, Fixkosten und geplante Posten),
6. schreibt den Diff ins `CHANGELOG.md` und verschiebt verarbeitete Dateien nach `analysiert/`.

## Schritt 4 — Prüfen und Version sichern

Eine Frage an dich selbst: **Führt jede Zahl auf eine Annahme oder eine Quelle zurück?** Wenn ja, sag Claude:

```
Zeig mir kurz, was sich in der Finanzplanung seit dem letzten Stand
geändert hat, und sichere dann diese Iteration als Version.
```

Claude fasst die Änderungen zusammen und sichert den Stand (per Git-Commit). Falls das Projekt noch keine Versionierung hat, richtet Claude sie beim ersten Mal automatisch ein. Du musst dafür kein Git können.

**Warum dieser Schritt Gold wert ist:** Die Versionierung ist die Zeitmaschine deiner Finanzplanung. Jeder gesicherte Stand bleibt für immer abrufbar. Du kannst nächste Woche fragen „was hat sich seit letztem Montag geändert?" und bekommst die genaue Antwort, Zahl für Zahl (wie der Änderungsmodus in Word, nur für den ganzen Ordner). Und weil jeder Stand gesichert ist, dürfen Excel und Dashboard bei jedem Lauf gefahrlos neu erzeugt werden: verloren geht nichts.

## Der wöchentliche Lauf (rollierend)

Du kannst den Skill so oft laufen lassen, wie du willst, typisch einmal die Woche. Er ist auf Wiederholung gebaut:

- **Der Anker ist immer heute.** Jeder Lauf beginnt mit einer kurzen Frage: „Wie viel liegt heute auf dem Bankkonto (und anderen nicht angebundenen Konten)?" Zahl nennen oder den letzten Wert per Klick bestätigen, fertig; Stripe- und PayPal-Saldo kommen automatisch live. Daraus entsteht Cash heute, und die ganze Vorschau rechnet ab da.
- **Überlappende Zeiträume sind kein Problem.** Jede Buchung trägt ihre Transaktions-ID, der Skill gleicht darüber ab: Bekanntes bleibt, Geändertes (z.B. eine spätere Erstattung) wird aktualisiert, Neues kommt dazu. Nichts wird doppelt gezählt.
- **Geplante Posten räumen sich selbst auf.** Ist ein vorgemerkter Posten inzwischen wirklich geflossen, hakt der Skill ihn ab (damit er nicht doppelt zählt: einmal als Plan, einmal als echte Buchung). Ist er überfällig, fragt der Skill nach: verschieben, streichen oder erledigt.
- **Fixkosten laufen einfach weiter.** Die Vertrags-Tabelle in `ANNAHMEN.md` wird Monat für Monat fortgeschrieben. Sieht der Skill in den Quellen etwas Wiederkehrendes, das dort fehlt, schlägt er es vor.

So beantwortet jeder Lauf dieselbe Frage neu: **Wie viel habe ich heute, und bis wann reicht es?**

## Zwischendurch: künftige Kosten vormerken (ohne Lauf)

Du musst nicht auf den Wochenlauf warten, wenn du weißt, dass etwas kommt. Sag Claude einfach:

```
Merk dir für die Finanzplanung: in 3 Wochen kommt eine Rechnung
über 300 Euro von der Agentur.
```

Claude trägt genau eine Zeile in die Geplante-Posten-Tabelle in `ANNAHMEN.md` ein und bestätigt sie dir. Beim nächsten Lauf ist der Posten im Forecast. Das funktioniert auch für erwartete Zuflüsse („die zweite Tranche über 50.000 kommt am 1. September") und für neue Dauerposten („ab sofort 89 Euro monatlich für Tool X", das landet in der Fixkosten-Tabelle).

## Weitere Quellen anbinden

Der Skill ist quellen-agnostisch. Willst du sevDesk, Pliant oder die Bank ergänzen:

1. Echten Export der Quelle besorgen (die Spalten müssen bekannt sein, nicht geraten).
2. Datei nach `exporte/<quelle>/_neu/` legen.
3. In `SOURCES.md` die Zeile der Quelle von `geplant` auf `aktiv` setzen.

Mehr braucht es nicht. Der Skill nimmt, was da ist, und meldet transparent, welche Quellen noch leer sind. So wächst die Planung Quelle um Quelle, ohne Umbau.

## Was im Bundle liegt

```
financial-planner/
├── README.md                          ← das hier (inkl. Connector-Setup)
├── vorlage/                           ← das Gerüst, zieht als finanzplanung/ ins Projekt
│   ├── CLAUDE.md                      ← Regeln: rechne nie still, nenne die Annahme
│   ├── SOURCES.md                     ← Quellen-Manifest: Einnahmen, Kosten, Kanäle, Belege-Intake
│   ├── KOSTEN-KATEGORIEN.md           ← gültige Kostenblöcke (Vorschlag, frei anpassbar)
│   ├── ANNAHMEN.md                    ← Konfiguration, Fixkosten (Verträge), Geplante Posten, Annahmen
│   ├── financial-planning.md          ← die Single Source of Truth
│   ├── CHANGELOG.md                   ← der Änderungs-Nachweis
│   ├── exporte/<quelle>/_neu|analysiert/   ← System-Exporte (Einnahmen + Kosten)
│   └── belege/_neu|analysiert/        ← lose Kostenbelege jeder Form, KI kategorisiert
└── skills/financial-planner/SKILL.md ← liest Quellen, baut Planung, Excel + Dashboard
```
