# Vom Board in den Code, und zurück

Die Entwicklungs-Seite des Anforderungs-Boards. Das Gegenstück zum Bundle `requirements-board`: dort entstehen die Karten (Anforderer-Seite), hier werden sie umgesetzt, auf **demselben** Notion-Board.

```
Notion-Board                 Claude (in deiner Codebase)         Notion-Board
────────────                 ───────────────────────────         ────────────
Karte: Ready, Backlog    →   /issue-implement                →   In Progress
oder nach Feedback           Karte + Kommentare lesen,
in In Progress               Plan-Modus, Freigabe, Umsetzung
                         →   /issue-done                     →   Kommentar + In Review
                             Bilanz je Akzeptanzkriterium        (Abnahme durch den
                                                                  Anforderer)
```

**Der volle Kreislauf mit dem Anforderer:** `requirement-create` legt Karten an, das Grooming stuft auf `Ready`, `/issue-implement` setzt um, `/issue-done` stellt auf Review, `requirement-feedback` bringt Befunde als Kommentar zurück und die Karte auf `In Progress`, und `/issue-implement` liest beim nächsten Zug den Feedback-Kommentar als neuen Arbeitsauftrag.

## Konventionen in dieser Anleitung

- **„Sag Claude:"** + Block, du tippst das in den **Chat** von Claude Code.
- Board-Wissen (IDs, Properties, Status-Namen) lebt in **einer** Datei: `.claude/rules/notion-board.md`. Sie kommt aus dem Bundle `requirements-board` und wird hier nur wiederverwendet.

## Voraussetzungen

- Standard-Bootstrap (`bash bootstrap.sh`) ist durchgelaufen, **Notion-Connector** verbunden (Plan-Check siehe requirements-board-README: Datenbankabfragen brauchen Notion Business plus Notion AI).
- **Das Board existiert bereits**, aufgesetzt oder übernommen über das Bundle `requirements-board`.
- Deine Codebase ist ein Projekt mit CLAUDE.md. Falls nicht, öffne Claude Code im Repo und sag: „Lies dieses Projekt und erzeuge eine CLAUDE.md mit Architektur, Konventionen und Build-Kommandos."

## Schritt 1 — Bundle in die Codebase holen

Sag Claude (er kennt sein Working-Verzeichnis und legt die Dateien passend ab):

```
Lade das Use-Case-Bundle "dev-board" aus dem Workshop-Repo:
https://github.com/affm777/ai-os-starter-rs/tree/main/claude/use-cases/dev-board

Platziere es in meinem aktuellen Projekt so:
- skills/issue-implement/   → .claude/skills/issue-implement/
- skills/issue-done/        → .claude/skills/issue-done/

Bestätige mir kurz, welche Dateien angekommen sind.
```

Danach `/exit` und `claude` neu starten, damit die zwei Skills geladen werden.

## Schritt 2 — Board-Regel-Datei übernehmen

Die Skills lesen `.claude/rules/notion-board.md`. Diese Datei ist beim Board-Besitzer bereits ausgefüllt (requirements-board, Schritt 3). Hol dir die ausgefüllte Fassung (IDs, Property-Namen, Status) und leg sie **identisch** unter `.claude/rules/notion-board.md` in deiner Codebase ab. Nicht neu erfinden: beide Seiten müssen auf dieselben IDs zeigen.

## Schritt 3 — Erste Karte umsetzen

Sag Claude:

```
Setz die Karte <Name> um.
```

oder, wenn du keine bestimmte im Kopf hast:

```
Zieh die nächste Ready-Karte aus dem Sprint und setz sie um.
```

Der Skill findet die Karte (egal ob `Ready`, im `Backlog` oder nach Feedback in `In Progress`), liest Beschreibung, Akzeptanzkriterien und alle Kommentare, geht in den **Plan-Modus** und legt dir einen Umsetzungsplan gegen die Codebase vor. Implementiert wird erst nach deiner Freigabe; erst dann wandert die Karte auf `In Progress`.

> **Tipp Modellwahl:** Den Plan mit dem stärksten verfügbaren Modell erstellen lassen, für die Umsetzung reicht oft ein schnelleres (`/model` wechselt jederzeit).

## Schritt 4 — Fertig melden

Sag Claude:

```
Fertig, meld die Karte ab.
```

`/issue-done` zieht Bilanz gegen die Akzeptanzkriterien (aus Session und Git-Log), schreibt den Prüf-Kommentar an die Karte und stellt sie auf `In Review`. Der Anforderer testet; sein Feedback kommt über `requirement-feedback` zurück, die Karte auf `In Progress`, und du beginnst wieder bei Schritt 3.

## Die zwei Dinge, auf die es ankommt

**Der Plan vor dem Code.** Der Plan-Modus ist keine Formalität. Er zwingt die Analyse (welche Module, welche Muster, welche Seiteneffekte) vor die erste Änderung, und du gibst frei, bevor etwas passiert. Ein abgelehnter Plan kostet zwei Minuten, ein falsch implementiertes Feature einen Nachmittag.

**Der prüfbare Kommentar.** Die Abnahme steht und fällt damit, dass der Anforderer das Ergebnis testen kann, ohne den Code zu lesen. Pro Akzeptanzkriterium ein Befund, dazu die konkreten Prüfschritte. „Ist umgesetzt" ist kein Kommentar.

## Was im Bundle liegt

```
dev-board/
├── README.md                        ← das hier
└── skills/
    ├── issue-implement/SKILL.md     ← Karte wird Plan, Plan wird Code
    └── issue-done/SKILL.md          ← Bilanz, Prüf-Kommentar, ab in den Review
```

Die Board-Regel-Datei `notion-board.md` liegt bewusst **nicht** hier, sondern im Bundle `requirements-board`: ein Board, eine Regel-Datei, vier Skills, zwei Rollen.
