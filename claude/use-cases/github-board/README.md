# Ein Board, das die Arbeit trägt

Anforderungen leben in Köpfen, Chats und Mails. Was daraus wird, weiß niemand genau: was ist offen, was läuft gerade, was ist eigentlich längst erledigt. Die üblichen Antworten (eine Excel-Liste, ein Kanal, ein Gedächtnis) halten genau so lange, bis mehr als eine Person beteiligt ist.

Dieses Bundle setzt ein **GitHub-Projektboard** auf und gibt euch vier Skills, die den vollen Kreislauf abdecken: vom formlosen Gedanken zum sauberen Ticket, vom Ticket zum Code, vom Code zurück in die Abnahme. Alles im selben Repo, in dem der Code ohnehin liegt.

```
Rohmaterial            Claude                    GitHub-Board
─────────────          ──────                    ────────────
Gespräch, Mail,    →   /issue-create        →    Issue im Backlog
Notiz, Beobachtung                               (Grooming hebt auf Ready)
                                                        │
                   →   /issue-implement     →    In Progress
                       Plan, Freigabe, Code
                   →   /issue-done          →    PR + In Review
                       Bilanz je Kriterium
Du testest,        →   /issue-feedback      →    Kommentar am Issue
etwas hakt                                       (zurück auf In Progress)
```

**Warum GitHub und nicht Notion:** Wenn euer Code ohnehin auf GitHub liegt, ist das Board keine zweite Welt, die synchron gehalten werden muss. Der Pull Request schließt das Ticket, der Sprint läuft von selbst weiter, und der Entwickler wechselt für ein Ticket nicht das Werkzeug. Arbeitet ihr ohne eigene Codebase oder soll der Anforderer nichts von GitHub sehen, ist das Bundle `requirements-board` (Notion) der bessere Weg.

## Konventionen in dieser Anleitung

- **„Sag Claude:"** + Block, du tippst das in den **Chat** von Claude Code.
- Board-Wissen (IDs, Feldnamen, Status) lebt in **einer** Datei: `.claude/rules/github-board.md`. Ändert sich das Board, änderst du diese Datei, nicht die Skills.

## Voraussetzungen

- Standard-Bootstrap (`bash bootstrap.sh`) ist durchgelaufen.
- **Ein GitHub-Repo**, in dem die Issues leben sollen. Das ist normalerweise das Repo eurer Codebase.
- **`gh` ist installiert und angemeldet.** Prüfen mit `gh auth status`. Fehlt es: `brew install gh`, dann `gh auth login`.
- **Der `project`-Scope.** Das ist die Stolperstelle, die alle erwischt: ein normaler `gh auth login` bringt ihn **nicht** mit, und ohne ihn scheitert jeder Board-Befehl mit einer Meldung, die nicht verrät, woran es lag.

  **Jetzt prüfen, nicht am Workshop-Tag:**
  ```bash
  gh project list --owner @me
  ```
  Kommt ein Scope-Fehler statt einer (auch leeren) Liste:
  ```bash
  gh auth refresh -s project --hostname github.com
  ```

## Schritt 1 — Bundle ins Projekt holen

Öffne Claude Code **in dem Repo, in dem die Issues leben sollen**, und sag Claude:

```
Lade das Use-Case-Bundle "github-board" aus dem Workshop-Repo:
https://github.com/affm777/ai-os-starter-rs/tree/main/claude/use-cases/github-board

Platziere es in meinem aktuellen Projekt so:
- rules/github-board.md      → .claude/rules/github-board.md
- board-doku.md              → ./board-doku.md
- board-setup.md             → ./board-setup.md   (brauche ich gleich einmal)
- skills/issue-create/       → .claude/skills/issue-create/
- skills/issue-feedback/     → .claude/skills/issue-feedback/
- skills/issue-implement/    → .claude/skills/issue-implement/
- skills/issue-done/         → .claude/skills/issue-done/
- issue-templates/*.yml      → .github/ISSUE_TEMPLATE/

Eine bereits ausgefüllte .claude/rules/github-board.md niemals überschreiben.

Bestätige mir kurz, welche Dateien angekommen sind.
```

Danach `/exit` und `claude` neu starten, damit die vier Skills geladen werden. **Das wird gern vergessen**, und dann heißt es „der Skill geht nicht", obwohl er nur noch nicht geladen ist.

## Schritt 2 — Board aufsetzen

**Habt ihr schon ein Projektboard?** Dann baut **kein** zweites. Sag Claude stattdessen:

```
Pass .claude/rules/github-board.md an unser bestehendes Board an: Felder und
Status auslesen, den Board-Adoptions-Block ausfüllen, alle IDs eintragen und
mit einem Test-Issue verifizieren.
```

Fertig, weiter zu Schritt 3.

**Noch keins?** Sag Claude:

```
Setz mir das Projektboard nach ./board-setup.md auf. Arbeite die Datei mit mir
Schritt für Schritt ab und trag die IDs am Ende in
.claude/rules/github-board.md ein.
```

Claude fragt nach euren **Epics** (den groben Themenfeldern), legt Projekt und Felder an, sagt dir für die drei Browser-Schritte genau, was zu klicken ist, und trägt am Ende alle IDs ein.

> **Plane den Browser mit ein.** `gh` kann Projekte und die meisten Felder anlegen, aber weder die Status-Optionen ändern noch das Sprint-Feld noch die Views. Das ist der Stand der GitHub-CLI, nicht eine Lücke der Anleitung. `board-setup.md` sagt bei jedem Schritt, welcher Weg gilt.

## Schritt 3 — Issue-Templates anpassen und pushen

Die Vorlagen liegen nach Schritt 1 schon in `.github/ISSUE_TEMPLATE/`, tragen aber noch Platzhalter. Sag Claude:

```
Setz in den Issue-Templates die Epic-Dropdowns auf unsere echten Themenfelder
und in config.yml die beiden Links auf unser Repo und unsere Kontaktadresse.
Danach committen und pushen.
```

**Templates greifen erst auf dem Default-Branch.** Auf einem Feature-Branch sieht sie niemand, und das ist ein verwirrender Fehler, weil alles richtig aussieht.

## Schritt 4 — Erstes Issue anlegen

Nimm **echtes** Rohmaterial, kein Beispiel. Eine Mail, eine Gesprächsnotiz, einen Fehler von dieser Woche. Sag Claude:

```
Mach aus folgendem Material ein Issue fürs Board:
<dein Text>
```

`/issue-create` bestimmt den Typ, prüft auf ein passendes Parent-Issue, schreibt das Ticket, legt es an, hängt es aufs Board und setzt die Felder. Es landet im **Backlog**, nicht auf `Ready`: das entscheidet das Grooming.

Dann die Prüffrage: **Könnte jemand das Ticket ziehen, ohne dich zu fragen?** Wenn nein, liegt es fast immer an den Akzeptanzkriterien. Nachschärfen, nochmal laufen lassen.

## Schritt 5 — Umsetzen und abnehmen

```
Setz Issue #<Nummer> um.
```

`/issue-implement` liest das Issue samt aller Kommentare, geht in den **Plan-Modus** und legt einen Umsetzungsplan gegen eure Codebase vor. Implementiert wird erst nach deiner Freigabe, erst dann wandert das Ticket auf `In Progress`.

Wenn es steht:

```
Fertig, meld das Issue ab.
```

`/issue-done` zieht Bilanz gegen die Akzeptanzkriterien, öffnet den Pull Request mit `Closes #<Nummer>` und schreibt den Prüf-Kommentar. Beim Merge schließt sich das Issue von selbst und rutscht auf `Done`.

Hakt beim Testen etwas:

```
Ich habe #<Nummer> getestet, folgendes Feedback: <deine Beobachtung>
```

`/issue-feedback` hängt einen strukturierten Kommentar an (✅ / ⚠️ / 🔴 je Befund, mit erwartetem Verhalten) und holt das Ticket zurück auf `In Progress`.

## Die drei Dinge, auf die es ankommt

**Akzeptanzkriterien.** Ohne sie ist es keine Anforderung, sondern ein Wunsch. Die Umsetzung muss daran ablesen können, wann sie fertig ist. Sind sie aus dem Material nicht ableitbar, gehört das Ticket ins Backlog, mit der offenen Frage im Text.

**Der Plan vor dem Code.** Der Plan-Modus ist keine Formalität. Er zwingt die Analyse (welche Module, welche Muster, welche Seiteneffekte) vor die erste Änderung, und du gibst frei, bevor etwas passiert.

**`Rejected` benutzen.** Der Status, den alle weglassen wollen. Ohne ihn gibt es nur zwei Wege, ein totes Ticket loszuwerden: fälschlich auf `Done` setzen oder für immer liegen lassen. Beides vergiftet das Board.

## Was im Bundle liegt

```
github-board/
├── README.md                          ← das hier
├── board-setup.md                     ← Board und Views anlegen. Einmalig.
├── board-doku.md                      ← wie das Board gedacht ist (Lifecycle, Felder, Parent/Sub)
├── rules/github-board.md              ← IDs, Feldnamen, Befehle. Die eine Stelle.
├── issue-templates/                   ← nach .github/ISSUE_TEMPLATE/ im Ziel-Repo
│   ├── bug_report.yml
│   ├── feature_request.yml
│   ├── task.yml
│   └── config.yml
└── skills/
    ├── issue-create/SKILL.md          ← Rohmaterial wird Ticket
    ├── issue-implement/SKILL.md       ← Ticket wird Plan, Plan wird Code
    ├── issue-done/SKILL.md            ← Bilanz, Pull Request, ab in den Review
    └── issue-feedback/SKILL.md        ← Befunde werden Kommentar plus Status zurück
```

**Die Notion-Variante desselben Denkmodells** liefern die Bundles `requirements-board` und `dev-board`. Gleiche Status, gleiche Felder, gleicher Kreislauf, nur eben in Notion und über zwei Bundles verteilt, weil dort Anforderer und Entwicklung in getrennten Verzeichnissen sitzen. Hier reicht eins, weil bei GitHub beide Rollen auf dasselbe Repo schauen.
