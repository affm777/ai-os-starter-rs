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

- Standard-Bootstrap (`bash bootstrap.sh`) ist durchgelaufen, **Notion-Connector** verbunden. Ein Plan-Upgrade brauchst du nicht: Die Datenbankabfrage läuft auf allen Plänen, auf Free und Plus lediglich mit einem Stundenlimit.
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

Hol zusätzlich die Board-Regel-Datei aus dem Nachbar-Bundle:
- claude/use-cases/requirements-board/rules/notion-board.md
  → .claude/rules/notion-board.md

Die Regel-Datei aber nur holen, falls .claude/rules/notion-board.md bei mir
noch nicht existiert. Eine bereits ausgefüllte niemals überschreiben.

Bestätige mir kurz, welche Dateien angekommen sind.
```

Danach `/exit` und `claude` neu starten, damit die zwei Skills geladen werden.

## Schritt 2 — Board-Regel-Datei übernehmen

Schritt 1 hat die Regel-Datei als leere Vorlage geholt. Die **IDs darin fehlen noch** — und ohne `DATASOURCE_ID` findet kein Skill eine Karte.

**Wenn es schon einen Board-Besitzer gibt** (jemand hat `requirements-board` aufgesetzt): Lass dir dessen ausgefüllte `.claude/rules/notion-board.md` schicken und überschreib deine Fassung damit **identisch**. Nicht neu erfinden, beide Seiten müssen auf dieselben IDs zeigen. Achtung: Die Datei liegt bei ihm im Anforderungs-Projekt, bei dir gehört sie in deine Codebase — sie wird also zwischen zwei Verzeichnissen kopiert.

**Wenn es noch keinen gibt:** Dann bist du gerade beide Rollen, Anforderer und Entwicklung. Dieses Bundle allein reicht dafür nicht, und zwar aus einem Grund, der leicht zu übersehen ist: `issue-implement` **setzt Karten um, es legt keine an**. Der Skill, der Karten anlegt, gehört zum Nachbar-Bundle. Ohne ihn stehst du vor einem leeren Board.

Installier deshalb zuerst `requirements-board` **vollständig** (README, `board-setup.md`, beide Skills), setz damit das Board auf und leg eine erste Karte an. Dann komm hierher zurück. **Bleib dabei in diesem Verzeichnis und leg kein neues Projekt an**, auch wenn die README des Nachbar-Bundles mit `/new-project` beginnt. Sonst landet die ausgefüllte Regel-Datei in einem anderen Projekt als deine Codebase, und die Skills hier finden sie nicht. Rechne dafür mit einer knappen Stunde, das meiste davon Board und Views.

Wenn dir jemand die Zeit abnehmen kann: das Board einmal aufsetzen zu lassen und dir nur die ausgefüllte `notion-board.md` geben zu lassen, ist der deutlich schnellere Weg.

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
