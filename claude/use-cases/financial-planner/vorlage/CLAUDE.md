# CLAUDE.md — Liquiditätsplanung

Dieses Verzeichnis ist eine reine Liquiditätsplanung, die nachvollziehbar bleibt. Das Modell: **Anker ist das Geld von heute** (Bank manuell, Stripe/PayPal live), die Zukunft wird davon vorwärts gerechnet (Fixkosten, geplante Posten, wiederkehrende Einnahmen), die Vergangenheit zeigt nur Flüsse ohne Saldo-Anspruch. Haupt-Kennzahl: der Monat, in dem das Geld eng wird. Kein EBIT, keine Steuerrücklage, das kommt später. Die Wahrheit ist Text, Excel und Dashboard sind nur Ansichten.

## Das Prinzip

- **`financial-planning.md` ist die Single Source of Truth.** Klartext, in Git versioniert. Jede Änderung ist ein Diff.
- **`auswertung.xlsx` und `dashboard.html` sind Renderings, keine Originale.** Beide werden bei jedem Lauf neu erzeugt und können nicht kaputtgehen. Das Dashboard ist komplett offline (keine externen Ressourcen), die Finanzdaten bleiben lokal.
- **`ANNAHMEN.md` trägt die Zukunft:** die Fixkosten-Tabelle (Verträge) und die Geplanten Posten (terminierte Einmal-Zahlungen, rein wie raus). Zwischendurch vormerken geht per Zuruf ("merk dir: in 3 Wochen 300 Euro Rechnung"), ohne vollen Lauf.
- **`exporte/` sind die Rohdaten der System-Quellen, unverändert.** Du wirfst neue Exporte in `exporte/<quelle>/_neu/`, der Skill verarbeitet sie und schiebt sie nach `exporte/<quelle>/analysiert/`.
- **`belege/` ist der Kosten-Eingang für lose Dateien.** Kosten, die in keinem angebundenen System liegen (nicht verbundenes Bankkonto, lose Rechnungen, Belege), wirfst du in beliebiger Form nach `belege/_neu/`. Der Skill liest sie, ordnet sie einem Kostenblock aus `KOSTEN-KATEGORIEN.md` zu und fragt bei Unklarheit nach. Details: `SOURCES.md`, Abschnitt Belege-Intake.

## Regeln beim Rechnen (PFLICHT)

1. **Rechne nie still.** Jede Zahl in der Planung führt auf eine benannte Annahme oder eine Quelldatei zurück. Wenn du eine Zahl schreibst, steht daneben, woher sie kommt.
2. **Annahmen leben in `ANNAHMEN.md`,** eine pro Zeile, im Klartext, mit Quelle. Keine Annahme versteckt in einer Formel.
3. **Jeder Lauf schreibt ins `CHANGELOG.md`:** was hat sich geändert, warum, aus welcher Datei. Nicht „Claude erklärt sich", sondern ein zeilenweiser Nachweis.
4. **Nichts erfinden.** Fehlt eine Zahl, bleibt sie offen und wird als offene Frage vermerkt, nicht geschätzt.
5. **Kosten nie in die falsche Schublade raten.** Jeder Beleg und jede Kostenzeile wird einem Block aus `KOSTEN-KATEGORIEN.md` zugeordnet. Ist die Zuordnung unklar oder passt in keinen Block, wird nachgefragt, nicht geschätzt. Neue Blöcke entstehen nur nach Bestätigung.
6. **Einnahmen nie still verbuchen.** Lässt sich ein Zufluss (typisch ein PayPal-Posten mit unbekanntem T-Code) nicht klar als Einnahme, Kostenblock oder Konto-Transfer einordnen, wird interaktiv gefragt, nicht geraten.
7. **Quellen-Manifest zuerst lesen:** `SOURCES.md` sagt, welche Quelle aktiv ist und wie sie liefert, und wie der Belege-Intake läuft.

## Ablauf pro Iteration

1. Neue Exporte in `exporte/<quelle>/_neu/` ablegen, lose Kostenbelege nach `belege/_neu/` (oder aktive Connector-Quelle wird live gezogen).
2. Skill `financial-planner` laufen lassen.
3. Er liest die neuen Daten, schreibt `financial-planning.md` fort, rendert `auswertung.xlsx` und `dashboard.html`, schreibt den Diff ins `CHANGELOG.md` und verschiebt Verarbeitetes nach `analysiert/`.
4. Du prüfst den Diff. Alles nachvollziehbar? Dann `git commit`.

## Regeln

- Sprache: Deutsch für Inhalte, Englisch nur für technische Begriffe.
- Echte Umlaute (ä, ö, ü, ß).
- Der Ordner gehört in Git. Du musst Git nicht können, aber jede Iteration wird committet, damit die Historie steht.
- Rohdaten mit sensiblen Inhalten (Lohndaten, Klarnamen) gehören nicht in dieses Verzeichnis. Nur aggregierte Finanzdaten.
