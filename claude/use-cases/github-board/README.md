# Ein Board, das die Arbeit trägt

Anforderungen leben in Köpfen, Chats und Mails. Was offen ist, was läuft und was längst erledigt ist, weiß niemand genau. Excel-Liste, Kanal oder Gedächtnis halten genau so lange, bis mehr als eine Person beteiligt ist.

Dieses Bundle setzt ein **GitHub-Projektboard** auf und gibt euch vier Skills für den vollen Kreislauf: vom formlosen Gedanken zum Ticket, vom Ticket zum Code, vom Code zurück in die Abnahme. Alles im selben Repo, in dem der Code ohnehin liegt.

## Zwei Rollen, zwei Wege

Die vier Skills teilen sich sauber auf zwei Rollen auf. **Niemand braucht alle vier.**

| Rolle | Wer das ist | Skills |
|---|---|---|
| **Product Owner** | Wer sagt, was gebaut werden soll, und am Ende prüft, ob es stimmt | `/issue-create`, `/issue-feedback` |
| **Entwicklung** | Wer es baut | `/issue-implement`, `/issue-done` |

Deshalb ist diese Anleitung dreigeteilt: **Teil A** richtet einmal alles ein und gilt für beide. Danach liest jeder nur seinen Teil, **B** oder **C**.

**Machst du beides selbst?** Dann arbeite A, B und C der Reihe nach durch. Der Ablauf funktioniert auch allein, er zwingt dich nur, die Anforderer-Brille kurz aufzusetzen, bevor du losbaust. Das ist der eigentliche Nutzen.

## Der Kreislauf

```
   PRODUCT OWNER                              ENTWICKLUNG
   ═════════════════════════                  ═════════════════════════

 1 /issue-create
   Notiz, Mail, Gespräch
   wird ein Ticket
         │
         ▼
     [Backlog]
         │
     Grooming: Kriterien,
     Size, Sprint
         │
         ▼
      [Ready] ─────── ÜBERGABE ─────────▶  2 /issue-implement
                                             liest Ticket samt Kommentaren,
                                             legt einen Plan vor, baut
                                             nach deiner Freigabe
                                                      │
                                                      ▼
                                               [In Progress]
                                                      │
                                           3 /issue-done
                                             Bilanz je Akzeptanzkriterium,
                                             Pull Request mit Closes #N
                                                      │
                                                      ▼
 4 du testest ◀────── ÜBERGABE ──────────────  [In Review]
         │
         ├── passt:  Pull Request mergen  ──▶  [Done]   (setzt GitHub selbst)
         │
         └── hakt:   /issue-feedback
                          │
                          └─ ÜBERGABE ─────▶  [In Progress]  weiter bei 2
```

Drei Übergaben, und der Kreis schließt sich: Was der Product Owner nicht abnimmt, landet als Kommentar wieder bei der Entwicklung, ohne dass jemand den Stand von Hand nachpflegt.

## Konventionen in dieser Anleitung

- **„Sag Claude:"** + Block, du tippst das in den **Chat** von Claude Code.
- Board-Wissen (IDs, Feldnamen, Status) lebt in **einer** Datei: `.claude/rules/github-board.md`. Ändert sich das Board, änderst du diese Datei, nicht die Skills.

---

# Teil A — Einrichtung (beide Rollen)

## Voraussetzungen

- Standard-Bootstrap (`bash bootstrap.sh`) ist durchgelaufen.
- **Ein GitHub-Repo**, in dem die Issues leben sollen. Das ist normalerweise das Repo eurer Codebase. **Beide Rollen arbeiten in einem Klon davon**, dann teilen sie sich die Board-Regel-Datei automatisch über Git.
- **`gh` ist installiert und angemeldet.** Prüfen mit `gh auth status`. Fehlt es: `brew install gh`, dann `gh auth login`.
- **Der `project`-Scope.** Ein normaler `gh auth login` bringt ihn **nicht** mit, und ohne ihn scheitert jeder Board-Befehl mit einer Meldung, die nicht verrät, woran es lag. Prüfen mit `gh project list --owner @me`. Kommt ein Scope-Fehler statt einer (auch leeren) Liste:
  ```bash
  gh auth refresh -s project --hostname github.com
  ```

## Schritt A1 — Bundle ins Projekt holen

Öffne Claude Code **im Repo, in dem die Issues leben sollen**, und sag Claude:

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

Danach `/exit` und `claude` neu starten, damit die Skills geladen werden. **Wird gern vergessen**, und dann heißt es „der Skill geht nicht", obwohl er nur nicht geladen ist.

> Ihr könnt die Skills der jeweils anderen Rolle liegen lassen, sie stören nicht. Einfacher ist es, alle vier zu holen und einmal gemeinsam ins Repo zu committen.

## Schritt A2 — Board aufsetzen

**Das macht genau einer im Team, nicht jeder.** Am Ende steht die ausgefüllte `.claude/rules/github-board.md`, und die geht über Git an alle anderen.

**Habt ihr schon ein Projektboard?** Dann baut **kein** zweites. Sag Claude stattdessen:

```
Pass .claude/rules/github-board.md an unser bestehendes Board an: Felder und
Status auslesen, den Board-Adoptions-Block ausfüllen, alle IDs eintragen und
mit einem Test-Issue verifizieren.
```

**Noch keins?** Sag Claude:

```
Setz mir das Projektboard nach ./board-setup.md auf. Arbeite die Datei mit mir
Schritt für Schritt ab und trag die IDs am Ende in
.claude/rules/github-board.md ein.
```

Claude fragt nach euren **Epics** (den groben Themenfeldern), legt Projekt und Felder an, sagt dir für die Browser-Schritte genau, was zu klicken ist, und trägt am Ende alle IDs ein.

> **Halte den Browser offen.** `gh` kann weder Status-Optionen ändern noch das Sprint-Feld noch die Views anlegen. Das ist der Stand der GitHub-CLI, keine Lücke der Anleitung. `board-setup.md` sagt bei jedem Schritt, welcher Weg gilt.

**Zum Schluss `.claude/rules/github-board.md` committen und pushen.** Alle anderen ziehen sie mit `git pull` und sind sofort arbeitsfähig. Das ist der Grund, warum bei GitHub beide Rollen im selben Repo sitzen sollten: die IDs werden nie von Hand herumgereicht.

## Schritt A3 — Issue-Templates anpassen

Die Vorlagen liegen nach A1 schon in `.github/ISSUE_TEMPLATE/`, tragen aber noch Platzhalter. Sag Claude:

```
Setz in den Issue-Templates die Epic-Dropdowns auf unsere echten Themenfelder
und in config.yml die beiden Links auf unser Repo und unsere Kontaktadresse.
Danach committen und pushen.
```

**Templates greifen erst auf dem Default-Branch.** Auf einem Feature-Branch sieht sie niemand, obwohl alles richtig aussieht.

---

# Teil B — Der Weg des Product Owners

Zwei Skills: einer macht aus Rohmaterial ein Ticket, einer bringt dein Testergebnis zurück ins Board.

## B1 — Ticket anlegen

Nimm **echtes** Rohmaterial, kein Beispiel. Eine Mail, eine Gesprächsnotiz, einen Fehler von dieser Woche. Sag Claude:

```
Mach aus folgendem Material ein Issue fürs Board:
<dein Text>
```

`/issue-create` bestimmt den Typ, prüft auf ein passendes Parent-Issue, legt das Ticket an, hängt es aufs Board und setzt die Felder. Es landet im **Backlog**, nicht auf `Ready`: das entscheidet das Grooming.

Dann die Prüffrage: **Könnte die Entwicklung das Ticket ziehen, ohne dich zu fragen?** Wenn nein, liegt es fast immer an den Akzeptanzkriterien. Nachschärfen, nochmal laufen lassen.

## B2 — Grooming: die Übergabe

Der Schritt, den kein Skill übernimmt, weil er eine Entscheidung ist und keine Schreibarbeit. Geh den Backlog nach Priority durch und heb die Tickets auf **`Ready`**, die wirklich ziehbar sind: Akzeptanzkriterien stehen, Size gesetzt, Sprint zugewiesen.

**`Ready` ist dein Versprechen an die Entwicklung**, dass sie loslegen kann, ohne nachzufragen. Alles andere bleibt im Backlog, auch wenn es dringend wirkt.

## B3 — Abnehmen oder zurückgeben

Steht ein Ticket auf **`In Review`**, ist die Entwicklung fertig und du bist dran. Im Kommentar von `/issue-done` steht je Akzeptanzkriterium, was erfüllt ist und wie du es prüfst.

**Passt es:** Pull Request mergen. Das Issue schließt sich von selbst und rutscht auf `Done`.

**Hakt etwas:**

```
Ich habe #<Nummer> getestet, folgendes Feedback: <deine Beobachtung>
```

`/issue-feedback` hängt einen strukturierten Kommentar an (✅ / ⚠️ / 🔴 je Befund, mit erwartetem Verhalten) und holt das Ticket zurück auf `In Progress`. Die Entwicklung sieht daran, dass es weitergeht.

> **Zitiere wörtlich, was du beobachtet hast**, nicht deine Deutung davon. „Ich habe dreimal auf Speichern geklickt und dachte, es hängt" ist für die Entwicklung mehr wert als „Speichern ist unübersichtlich".

---

# Teil C — Der Weg der Entwicklung

Zwei Skills: einer holt das Ticket in den Code, einer bringt es zur Abnahme.

## C1 — Ticket umsetzen

```
Setz Issue #<Nummer> um.
```

Oder, wenn du keins im Kopf hast:

```
Zieh die nächste Ready-Karte aus dem Sprint und setz sie um.
```

`/issue-implement` liest das Issue samt **aller Kommentare**, geht in den **Plan-Modus** und legt einen Umsetzungsplan gegen eure Codebase vor. Gebaut wird erst nach deiner Freigabe, erst dann wandert das Ticket auf `In Progress`.

> **Kam das Ticket nach Feedback zurück, ist der jüngste Kommentar der Arbeitsauftrag**, nicht die ursprüngliche Beschreibung. Der Skill weiß das, aber es lohnt sich, selbst hinzusehen.

> **Tipp Modellwahl:** Den Plan mit dem stärksten verfügbaren Modell erstellen lassen, für die Umsetzung reicht oft ein schnelleres (`/model` wechselt jederzeit).

## C2 — Fertig melden

```
Fertig, meld das Issue ab.
```

`/issue-done` zieht Bilanz gegen die Akzeptanzkriterien, öffnet den Pull Request mit `Closes #<Nummer>` und schreibt den Prüf-Kommentar ans Issue. Das Ticket geht auf `In Review`, der Product Owner ist dran.

**`Closes #<Nummer>` ist der Kern des Ablaufs.** Beim Merge schließt sich das Issue automatisch und rutscht auf `Done`. Fehlt die Zeile, reißt der automatische Teil der Kette, und niemand merkt es, bis sich erledigte Tickets stapeln.

**Der Prüf-Kommentar entscheidet über die Abnahme.** Er muss jemanden in die Lage versetzen, das Ergebnis zu testen, ohne den Code zu lesen. „Ist umgesetzt" ist kein Kommentar.

---

## Die drei Dinge, auf die es ankommt

**Akzeptanzkriterien.** Ohne sie ist es keine Anforderung, sondern ein Wunsch. Sind sie aus dem Material nicht ableitbar, gehört das Ticket ins Backlog, mit der offenen Frage im Text.

**Der Plan vor dem Code.** Er zwingt die Analyse vor die erste Änderung, und du gibst frei, bevor etwas passiert. Ein abgelehnter Plan kostet zwei Minuten, ein falsch gebautes Feature einen Nachmittag.

**`Rejected` benutzen.** Sonst gibt es nur zwei Wege, ein totes Ticket loszuwerden: fälschlich auf `Done` setzen oder für immer liegen lassen. Beides vergiftet das Board.

## Was im Bundle liegt

```
github-board/
├── README.md                          ← das hier
├── board-setup.md                     ← Board und Views anlegen. Einmalig, einer im Team.
├── board-doku.md                      ← wie das Board gedacht ist (Lifecycle, Felder, Parent/Sub)
├── rules/github-board.md              ← IDs, Feldnamen, Befehle. Die eine Stelle.
├── issue-templates/                   ← nach .github/ISSUE_TEMPLATE/ im Ziel-Repo
│   ├── bug_report.yml
│   ├── feature_request.yml
│   ├── task.yml
│   └── config.yml
└── skills/
    ├── issue-create/SKILL.md          ← PO:  Rohmaterial wird Ticket
    ├── issue-feedback/SKILL.md        ← PO:  Befunde werden Kommentar plus Status zurück
    ├── issue-implement/SKILL.md       ← Dev: Ticket wird Plan, Plan wird Code
    └── issue-done/SKILL.md            ← Dev: Bilanz, Pull Request, ab in den Review
```

Denselben Kreislauf in Notion liefern die Bundles `requirements-board` und `dev-board`.
