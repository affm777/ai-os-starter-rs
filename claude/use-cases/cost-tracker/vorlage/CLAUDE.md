# CLAUDE.md — Kosten-Tracking

Dieses Verzeichnis ist ein reines Kosten-Tracking, das nachvollziehbar bleibt. Es beantwortet: **wohin geht mein Geld, je Kostenblock und je Standort, und was davon ist fix?** Jede Zahl ist eine Zahl, die tatsächlich geflossen ist. Bewusst NICHT hier drin: Umsätze, Kontostand, Forecast, Liquidität. Das ist ein anderer Use Case. Die Wahrheit ist Text, Excel und Dashboard sind nur Ansichten.

## Das Prinzip

- **`kosten.md` ist die Single Source of Truth.** Klartext, in Git versioniert. Jede Änderung ist ein Diff.
- **`auswertung.xlsx` und `dashboard.html` sind Renderings, keine Originale.** Beide werden bei jedem Lauf neu erzeugt, nie zurückgelesen und können nicht kaputtgehen. Das Dashboard ist komplett offline (keine externen Ressourcen), die Finanzdaten bleiben lokal.
- **Zwei Zuordnungs-Dimensionen:** jeder Posten bekommt einen Kostenblock aus `KOSTEN-KATEGORIEN.md` und einen Standort aus `STANDORTE.md` (inklusive `uebergreifend` für zentrale Kosten). Beide Taxonomien sind editierbare Dateien, kein Code.
- **`ANNAHMEN.md` trägt das Drumherum:** die Fixkosten-Tabelle (Verträge, für Fix-gegen-Variabel und den Vollständigkeits-Check) und die Erwarteten Kosten (terminierte künftige Zahlungen, die in keiner Ist-Summe mitzählen). Zwischendurch vormerken geht per Zuruf („merk dir: in 3 Wochen 300 Euro Rechnung"), ohne vollen Lauf.
- **`exporte/` sind die Rohdaten der System-Quellen, unverändert.** Du wirfst neue Exporte in `exporte/<quelle>/_neu/`, der Skill verarbeitet sie und schiebt sie nach `exporte/<quelle>/analysiert/`.
- **`belege/` ist der Eingang für lose Dateien.** Kosten, die in keinem System liegen (Barzahlungen, lose Rechnungen, Fotos), wirfst du in beliebiger Form nach `belege/_neu/`. Details: `SOURCES.md`, Abschnitt Belege-Intake.

## Regeln beim Rechnen (PFLICHT)

1. **Rechne nie still.** Jede Zahl in der Auswertung führt auf eine Quelldatei oder eine benannte Annahme zurück. Wenn du eine Zahl schreibst, steht daneben, woher sie kommt.
2. **Annahmen leben in `ANNAHMEN.md`,** eine pro Zeile, im Klartext, mit Quelle. Keine Annahme versteckt in einer Formel.
3. **Jeder Lauf schreibt ins `CHANGELOG.md`:** was hat sich geändert, warum, aus welcher Datei. Nicht „Claude erklärt sich", sondern ein zeilenweiser Nachweis.
4. **Nichts erfinden, nichts prognostizieren.** Fehlt eine Zahl, bleibt sie offen und wird als offene Frage vermerkt, nicht geschätzt. Es gibt keine Vorschau und keine Fortschreibung: nur Ist.
5. **Nie in die falsche Schublade raten.** Jeder Posten wird einem Block aus `KOSTEN-KATEGORIEN.md` UND einem Standort aus `STANDORTE.md` zugeordnet. Ist eine Zuordnung unklar, wird nachgefragt, nicht geschätzt. Neue Blöcke, Standorte und Regel-Zeilen entstehen nur nach Bestätigung.
6. **Einnahmen werden nie verbucht, nur gezählt.** Zuflüsse in den Quellen sind nicht Thema dieses Tools; sie werden übersprungen und im Stand als Zähler ausgewiesen. Einzige Ausnahme: Erstattungen früherer eigener Ausgaben, die sind negative Kosten im Ursprungsblock.
7. **Empfehlungen nur mit Beleg.** Jede Beobachtung stammt aus dem festen Katalog der SKILL.md und nennt die Buchungs-IDs, auf denen sie beruht. Ursachen werden erfragt, nicht behauptet.
8. **Quellen-Manifest zuerst lesen:** `SOURCES.md` sagt, welche Quelle aktiv ist und wie sie liefert.

## Ablauf pro Iteration

1. Neue Exporte in `exporte/<quelle>/_neu/` ablegen, lose Kostenbelege nach `belege/_neu/`.
2. Skill `cost-tracker` laufen lassen.
3. Er liest die neuen Daten, schreibt `kosten.md` fort, rendert `auswertung.xlsx` und `dashboard.html`, schreibt den Diff ins `CHANGELOG.md` und verschiebt Verarbeitetes nach `analysiert/`.
4. Du prüfst den Diff. Alles nachvollziehbar? Dann `git commit`.

## Regeln

- Sprache: Deutsch für Inhalte, Englisch nur für technische Begriffe.
- Echte Umlaute (ä, ö, ü, ß).
- Der Ordner gehört in Git. Du musst Git nicht können, aber jede Iteration wird committet, damit die Historie steht.
- Rohdaten mit sensiblen Inhalten (Lohndaten, Klarnamen) gehören nicht in dieses Verzeichnis. Nur aggregierte Finanzdaten.
