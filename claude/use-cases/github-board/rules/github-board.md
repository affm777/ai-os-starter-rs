# GitHub-Board: IDs, Felder, Befehle

Die eine Stelle, an der Board-Wissen lebt. Alle vier Skills lesen diese Datei, keiner hat IDs fest verdrahtet. Ändert sich das Board, änderst du hier, nicht die Skills.

**Konzept dahinter** (Lifecycle, Feldbedeutung, Parent/Sub-Regeln): siehe `board-doku.md`. Diese Datei hier hält die IDs, die die API braucht.

## Repo und Projekt

| Ding | Wert |
|---|---|
| Repo | `<noch nicht gesetzt>` (Format: `owner/repo`) |
| GitHub-Handle des Board-Besitzers | `<noch nicht gesetzt>` |
| Projekt-Name | `<noch nicht gesetzt>` |
| Projekt-Nummer | `<noch nicht gesetzt>` |
| Projekt-ID | `<noch nicht gesetzt>` (Format: `PVT_...`) |
| Board-URL | `<noch nicht gesetzt>` |

**Stehen hier noch Platzhalter, ist das Board nicht aufgesetzt.** Dann `board-setup.md` abarbeiten. Kein Skill darf gegen leere IDs laufen.

## Account-Guard (vor jedem gh-Aufruf)

Wenn du mehrere GitHub-Accounts hast, greift `gh` sonst auf den falschen zu und legt Issues im falschen Repo an. Der Guard ist billig, der Fehler ist teuer:

```bash
[ "$(gh api user --jq .login 2>/dev/null)" = "<HANDLE>" ] || gh auth switch --user "<HANDLE>"
```

**`<HANDLE>` an beiden Stellen durch den Handle aus der Tabelle oben ersetzen** (Zeile „GitHub-Handle des Board-Besitzers"). Bleibt einer stehen, scheitert das nicht mit einer GitHub-Meldung, sondern mit einem Bash-Syntaxfehler (`syntax error near unexpected token`), weil die Shell die spitzen Klammern als Umleitung liest. Das passiert dann bei **jedem** Skill-Aufruf und sieht aus, als sei der Skill kaputt.

Hast du nur einen Account, schadet die Zeile nicht.

## Feld- und Options-IDs

Diese Werte kommen aus `board-setup.md` Schritt 6. Alle als `PVTSSF_...` (Single-Select) beziehungsweise `PVTIF_...` (Iteration).

**Status** `<noch nicht gesetzt>`

| Option | ID |
|---|---|
| Backlog | `<noch nicht gesetzt>` |
| Ready | `<noch nicht gesetzt>` |
| In Progress | `<noch nicht gesetzt>` |
| In Review | `<noch nicht gesetzt>` |
| Ready for Deployment | `<noch nicht gesetzt>` |
| Done | `<noch nicht gesetzt>` |
| Rejected | `<noch nicht gesetzt>` |

**Priority** `<noch nicht gesetzt>`: P0-blocker `<>` · P1-high `<>` · P2-normal `<>` · P3-nice-to-have `<>`

**Size** `<noch nicht gesetzt>`: XS `<>` · S `<>` · M `<>` · L `<>`

**Type** `<noch nicht gesetzt>`: Bug `<>` · Feature `<>` · Task `<>`

**Area** `<noch nicht gesetzt>`: (eure Codebase-Zonen, aus dem Setup)

**Epic** `<noch nicht gesetzt>`: (eure Themenfelder, aus dem Setup)

**Sprint** (Iteration) `<noch nicht gesetzt>` — hat keine statischen Optionen, der aktive Sprint wird zur Laufzeit abgeleitet (siehe unten).

> IDs sehen veraltet aus oder ein Aufruf scheitert? Neu ableiten:
> `gh project field-list <NUMMER> --owner <HANDLE> --format json`

## Board-Adoption (bestehendes Board übernommen)

Nur ausfüllen, wenn ihr ein **gewachsenes Board** übernommen habt statt eins neu aufzusetzen. Dann weichen eure Namen von den Standardwerten ab, und die Skills müssen eure kennen, nicht die aus der Doku.

| Rolle im Ablauf | Standard-Name | Euer Name |
|---|---|---|
| Neu angelegt, ungegroomt | `Backlog` | `<eurer>` |
| Ziehbar, gegroomt | `Ready` | `<eurer>` |
| Arbeits-Status (`REWORK_STATUS`) | `In Progress` | `<eurer>` |
| Abnahme-Status (`REVIEW_STATUS`) | `In Review` | `<eurer>` |
| Erledigt | `Done` | `<eurer>` |
| Verworfen | `Rejected` | `<eurer>` |

Fehlt bei euch ein Status ganz (viele Boards haben kein `Rejected`), tragt den nächstliegenden ein und haltet fest, dass er fehlt. Erfindet keinen dazu: ein Board, das die Skills umbauen, ist kein übernommenes Board mehr.

Gleiches gilt für Property-Namen. Heißt euer Epic-Feld `Bereich` oder euer Size-Feld `Aufwand`, tragt das hier ein.

## Aktiven Sprint ableiten (nie hart eintragen)

```bash
gh api graphql -f query='{ node(id:"<SPRINT_FIELD_ID>"){ ... on ProjectV2IterationField { configuration { iterations { id title startDate duration } } } } }'
```

`iterations[0]` ist der laufende Sprint. Seine `id` wandert unten in `--iteration-id`.

## Hilfsbefehle

**Board-Item-ID zu einer Issue-Nummer `N` finden** (das Board kennt Issues nicht über ihre Nummer, sondern über eine eigene Item-ID):

```bash
gh project item-list <NUMMER> --owner <HANDLE> --limit 400 --format json | python3 -c "
import sys,json; N=$N
for it in json.load(sys.stdin).get('items',[]):
    if it.get('content',{}).get('number')==N: print(it['id']); break"
```

`--limit 400` ist kein Zierrat: die Standardgrenze liegt bei 30 Items, alles dahinter fehlt sonst kommentarlos.

**Kommt bei einem gerade erst hinzugefügten Item nichts zurück, ist das kein Paginierungsproblem, sondern Indexierungsverzögerung.** Die Projects-API braucht ein paar Sekunden, bis ein frisches Item hier auftaucht. Warte nicht darauf: `gh project item-add --format json` gibt die Item-ID sofort zurück (siehe unten). Dieser Suchbefehl ist für **bestehende** Items gedacht.

**Single-Select-Feld setzen** (Status, Priority, Size, Type, Epic, Area):

```bash
gh project item-edit --project-id <PROJEKT_ID> --id <ITEM_ID> --field-id <FELD_ID> --single-select-option-id <OPTION_ID>
```

**Sprint setzen:**

```bash
gh project item-edit --project-id <PROJEKT_ID> --id <ITEM_ID> --field-id <SPRINT_FELD_ID> --iteration-id <ITER_ID>
```

**Frisches Issue aufs Board holen** (Pflicht, bevor irgendein Feld gesetzt werden kann):

```bash
gh project item-add <NUMMER> --owner <HANDLE> --url <ISSUE_URL> --format json
```

**Immer mit `--format json`.** Die Antwort enthält die `id` des neuen Board-Items, und die brauchst du direkt danach zum Feldsetzen. Ohne sie musst du sie nachschlagen und läufst in die Indexierungsverzögerung von oben.

## Schreibstil in Issues und Kommentaren

- **Sprache: Deutsch.** Arbeitet ihr international oder mit externen Entwicklern, stellt hier auf Englisch um und haltet es dann durchgehend so. Ein halb übersetztes Board ist schlimmer als ein konsequent englisches.
- Knapp, nachvollziehbar, überfliegbar. Der Entwickler liest viele davon.
- Umlaute ausschreiben. Keine Gedankenstriche, stattdessen Komma, Punkt, Doppelpunkt, Klammern.
- Screenshots hängt der Nutzer selbst in der GitHub-Oberfläche an. Im Text darauf verweisen mit „(Screenshot separat angehängt)".

## Issue-Templates

Drei Vorlagen in `.github/ISSUE_TEMPLATE/` geben die Form vor. Wer ein Issue frei formuliert, spiegelt trotzdem diese Struktur:

- **Bug** (`bug_report.yml`): Was ist passiert · Schritte zur Reproduktion · Erwartetes Verhalten · Logs · Umgebung
- **Feature** (`feature_request.yml`): Problem oder Anwendungsfall · Vorgeschlagene Lösung · Akzeptanzkriterien (Checkboxen) · Alternativen
- **Task** (`task.yml`): Kontext · Was zu tun ist · Definition of Done · Referenzen

Parent, Sub-Issue oder Standalone, plus die Epic/Area/Priority/Size-Systematik: siehe `board-doku.md`.
