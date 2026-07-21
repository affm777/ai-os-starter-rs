# Board-Setup: einmalig, vor allem anderen

**Wofür:** Das GitHub-Projektboard anlegen, das die vier Skills bespielen. **Ohne dieses Board läuft kein Skill.** Das hier ist Schritt null.

**Wie benutzen:** Diese Datei Claude geben und sagen: „Setz mir das Projektboard nach `board-setup.md` auf." Claude arbeitet sie mit dir ab und trägt am Ende die IDs in `.claude/rules/github-board.md` ein.

**Dauer:** rund 20 bis 30 Minuten. Einmalig.

---

## Die eine Sache, die du vorher wissen musst

**Ein Teil dieses Setups geht nicht über die Kommandozeile.** `gh` kann Projekte und die meisten Felder anlegen, aber zwei Dinge nicht:

| Was | Weg |
|---|---|
| Projekt anlegen, mit Repo verknüpfen | `gh` |
| Felder Priority, Size, Type, Area, Epic | `gh` |
| IDs auslesen | `gh` |
| **Status-Optionen anpassen** | **Browser** (`gh` kann Optionen eines bestehenden Feldes nicht ändern) |
| **Sprint-Feld (Iteration)** | **Browser** (`gh field-create` kennt nur TEXT, SINGLE_SELECT, DATE, NUMBER) |
| **Die vier Views** | **Browser** (`gh project` hat keine View-Befehle) |

Das ist keine Nachlässigkeit der Anleitung, sondern der Stand der GitHub-CLI. Halte den Browser also offen, und plane die Klick-Schritte ein. Claude sagt dir jeweils genau, was zu klicken ist.

---

## Schritt 0: Die Frage, die alles andere überflüssig machen kann

**Habt ihr schon ein Projektboard?**

Wenn ja: **hier aufhören.** Kein zweites bauen. Stattdessen den **Board-Adoptions-Block** in `.claude/rules/github-board.md` an euer bestehendes Board anpassen und die IDs von dort holen (Schritt 6 zeigt, wie). Ein zweites Board neben einem gewachsenen ist der schnellste Weg, dass beide sterben.

Nur weiterlesen, wenn es wirklich noch keins gibt.

## Schritt 1: Zugang prüfen, bevor irgendetwas gebaut wird

`gh project` braucht einen eigenen OAuth-Scope, den ein normaler `gh auth login` **nicht** mitbringt. Das ist die häufigste Stolperstelle im ganzen Setup, und sie meldet sich später mit einer Fehlermeldung, die nicht verrät, woran es lag.

```bash
gh auth status
gh project list --owner @me
```

Kommt bei der zweiten Zeile ein Scope-Fehler:

```bash
gh auth refresh -s project --hostname github.com
```

Danach `gh project list --owner @me` noch einmal. **Erst wenn das eine (auch leere) Liste zurückgibt, weiterlesen.**

## Schritt 2: Epic-Werte klären

Die einzige Stelle, die pro Team anders aussieht. **Epics sind die groben Themenfelder**, meist die Produkte, Systeme oder Schichten, an denen gearbeitet wird.

Frag den Nutzer: „Welche Systeme, Produkte oder Bereiche betreut ihr? Die werden die Epics."

**Nicht raten.** Fehlt die Antwort, mit `Sonstiges` als einzigem Wert starten und später ergänzen. Ein falsches Epic-Set ist schlimmer als ein leeres, weil danach jedes Issue in die falsche Schublade wandert.

Dasselbe gilt für **Area** (welche Zone der Codebase wird berührt, etwa `frontend`, `backend`, `infra`, `docs`). Epic und Area sind bewusst zwei Achsen: Epic ist das Produktthema (vertikal), Area die Codebase-Zone (horizontal). Ein Issue hat meist von jedem eins.

## Schritt 3: Projekt anlegen und mit dem Repo verknüpfen

```bash
gh project create --owner <HANDLE> --title "<Board-Name>" --format json
```

`--format json` liefert **Nummer**, **URL** und die **Projekt-ID** (`PVT_...`) in einem Rutsch. Alle drei notieren, damit ist Schritt 6 zur Hälfte schon erledigt.

Dann mit dem Repo verknüpfen, damit Issues aus dem Repo dort andocken:

```bash
gh project link <NUMMER> --owner <HANDLE> --repo <HANDLE>/<repo>
```

> **Hier nicht `@me` verwenden.** `gh project link` löst die Abkürzung als Einziges der `project`-Befehle nicht auf und bricht mit „has different owner from '@me'" ab, was nach einem Rechteproblem klingt, aber keines ist. Überall sonst darf `@me` stehen, hier muss der echte Handle hin.

> **Persönliches Board oder Organisation?** `--owner @me` legt es unter deinem Account an. Gehört es dem Team, statt `@me` den Org-Namen setzen. Ein Board unter einem Privataccount, an das die Kollegen nicht kommen, ist der zweithäufigste Fehler nach dem fehlenden Scope.

## Schritt 4: Status-Optionen anpassen (Browser)

GitHub legt jedes neue Projekt mit einem Status-Feld an, das `Todo`, `In Progress` und `Done` enthält. Ihr braucht sieben Werte. `gh` kann Optionen eines bestehenden Feldes nicht ändern, das geht nur im Browser.

Board öffnen, dann: **⌄ neben einer Spaltenüberschrift → Edit field** (oder Projekt-Einstellungen → Fields → Status).

Diese sieben Optionen herstellen, in dieser Reihenfolge:

| Status | Bedeutung |
|---|---|
| `Backlog` | Idee oder offener Punkt. Kein Sprint, Grooming nicht abgeschlossen. |
| `Ready` | Akzeptanzkriterien stehen, Size gesetzt, Sprint zugewiesen. Ziehbar. |
| `In Progress` | Branch steht, es wird gearbeitet. |
| `In Review` | PR offen, wartet auf CI und Review. |
| `Ready for Deployment` | Vom Product Owner fachlich abgenommen, wartet auf Merge und Auslieferung. |
| `Done` | Ausgeliefert. |
| `Rejected` | Getriaged und verworfen (Duplikat, außerhalb des Scopes, überholt). |

**Die Namen sind bewusst englisch** und bewusst genau diese sieben. Nicht eindeutschen, nicht kürzen. `Rejected` wirkt verzichtbar, ist es aber nicht: es ist der einzige Weg, ein Issue zu beerdigen, ohne zu behaupten, es sei fertig. Ohne diesen Status sammeln sich tote Karten im Backlog, bis niemand mehr hinsieht.

> **`Done` umbenennen oder behalten, aber nicht löschen und neu anlegen.** An dieser Option hängt die eingebaute Automatik „Item closed", und die ist der Grund, warum `Closes #<nr>` im Pull Request später überhaupt wirkt. Wird die Option gelöscht und neu erzeugt, zeigt der Workflow ins Leere. Danach unter **Projekt-Einstellungen → Workflows** prüfen, dass „Item closed" aktiv ist und auf eure `Done`-Option zeigt. Fällt das aus, merkt es niemand sofort: es zeigt sich Wochen später als „Issues stapeln sich in In Review".

## Schritt 5: Die restlichen Felder anlegen

Fünf Felder per CLI. Die Epic- und Area-Werte aus Schritt 2 einsetzen:

```bash
gh project field-create <NUMMER> --owner @me --name "Priority" --data-type SINGLE_SELECT \
  --single-select-options "P0-blocker,P1-high,P2-normal,P3-nice-to-have"

gh project field-create <NUMMER> --owner @me --name "Size" --data-type SINGLE_SELECT \
  --single-select-options "XS,S,M,L"

gh project field-create <NUMMER> --owner @me --name "Type" --data-type SINGLE_SELECT \
  --single-select-options "Bug,Feature,Task"

gh project field-create <NUMMER> --owner @me --name "Area" --data-type SINGLE_SELECT \
  --single-select-options "<eure Zonen, kommagetrennt>"

gh project field-create <NUMMER> --owner @me --name "Epic" --data-type SINGLE_SELECT \
  --single-select-options "<eure Themen aus Schritt 2, kommagetrennt>"
```

Was die Werte bedeuten, steht in `board-doku.md` (Priority §4, Size §4). Kurz:

- **Priority:** P0 heißt alles stehenlassen, P3 heißt wenn Kapazität übrig ist.
- **Size:** XS unter 2 Stunden, S unter einem Tag, M ein bis drei Tage, L darüber (und dann meist ein Kandidat zum Splitten).

**Sprint-Feld (Browser).** `gh` kann keine Iteration-Felder anlegen. Im Board: **+ rechts neben der letzten Spalte → New field → Iteration**, Name `Sprint`, Dauer 2 Wochen. GitHub erzeugt die Sprints dann selbst fortlaufend, und die Skills leiten den aktiven zur Laufzeit ab. Das ist der eine Vorteil gegenüber Notion, wo der Sprintfilter von Hand umgestellt werden muss.

## Schritt 6: IDs auslesen und eintragen

Jetzt existiert alles, und die IDs lassen sich ziehen:

```bash
gh project field-list <NUMMER> --owner @me --format json
```

Die Ausgabe enthält pro Feld die `id` und bei Single-Selects alle `options` mit ihren IDs. Die Projekt-ID (`PVT_...`) hast du schon aus Schritt 3, sonst:

```bash
gh project view <NUMMER> --owner @me --format json --jq .id
```

**Alles davon in `.claude/rules/github-board.md` eintragen.** Jeder Platzhalter in spitzen Klammern muss weg, und zwar **überall, nicht nur in den Tabellen**: auch `<HANDLE>` im Account-Guard (dort steht er zweimal in einer Zeile) und `<SPRINT_FIELD_ID>` im GraphQL-Aufruf. **Erst danach funktionieren die Skills.**

> Ein übersehener `<HANDLE>` im Guard ist besonders unangenehm, weil er nicht als GitHub-Fehler auftaucht, sondern als Bash-Syntaxfehler bei **jedem** Skill-Aufruf.

## Schritt 7: Die vier Views anlegen (Browser)

`gh project` hat keine View-Befehle, das ist reine Klick-Arbeit. Im Board jeweils **+ neben dem Tab-Namen → New view**, dann Layout und Filter setzen.

**Current Sprint** (Layout `Board`, gruppiert nach `Status`) — das tägliche Arbeitsbrett:
```
sprint:@current
```

**Backlog** (Layout `Table`, sortiert nach Priority absteigend) — zum Groomen:
```
status:"Backlog" no:"Sub-issues progress"
```
Das `no:"Sub-issues progress"` hält Parent-Issues raus, sodass nur atomar ziehbare Punkte übrig bleiben. Ohne das verstopfen die Container die Liste.

> **Nicht `-has:sub-issues` verwenden**, auch wenn es naheliegt. `has:` kennt nur `assignee`, `label` und echte Feldnamen. Ein Feld namens `sub-issues` gibt es nicht, das eingebaute heißt `Sub-issues progress`. Und GitHub **meldet unbekannte `has:`-Werte nicht als Fehler, sondern ignoriert den Filter still.** Die Ansicht sieht dann korrekt aus und filtert nichts.

**By Epic** (Layout `Board`, gruppiert nach `Epic`) — Themen-Überblick:
```
-status:"Done" -status:"Rejected"
```

**Blockers** (Layout `Table`) — was gerade brennt:
```
priority:"P0-blocker" no:"Sub-issues progress" -status:"Done" -status:"Rejected"
```
Stehen hier mehr als fünf Punkte, ist das kein Board-Problem, sondern ein Planungsproblem.

> `sprint:@current` ist der Filter, den Notion nicht kann. GitHub kennt den aktiven Sprint selbst, du musst beim Sprintwechsel nichts umstellen.

## Schritt 8: Issue-Templates ins Repo

Die vier Dateien aus `issue-templates/` nach `.github/ISSUE_TEMPLATE/` im Ziel-Repo kopieren, dann committen und pushen. **Vorher zwei Stellen anpassen:**

- In allen drei Templates die **Epic-Dropdowns** auf eure Werte aus Schritt 2 setzen. Sie stehen dort als Platzhalter.
- In `config.yml` die beiden **Links** auf euer Repo und eure Kontaktadresse setzen.

Templates greifen erst, wenn sie auf dem Default-Branch liegen. Auf einem Feature-Branch sieht sie niemand.

## Schritt 9: Verifizieren, nicht hoffen

Die Bestätigungen der Schreibbefehle beweisen nichts über die Filter. **Drei Test-Issues anlegen**, die sich gezielt unterscheiden:

| Issue | Status | Sprint | Priority | Besonderheit | Muss auftauchen in |
|---|---|---|---|---|---|
| A | `In Review` | aktueller | `P0-blocker` | — | Current Sprint, Blockers |
| B | `Backlog` | leer | `P2-normal` | — | Backlog |
| C | `Backlog` | leer | `P0-blocker` | **hat ein Sub-Issue** | **nirgends** (weder Backlog noch Blockers) |

Dann **jede View einzeln im Browser öffnen** und prüfen: Zeigt Current Sprint nur A? Zeigt Backlog nur B? Zeigt Blockers nur A?

**Issue C ist der wichtigste Test**, auch wenn er lästig ist (ein Sub-Issue anlegen und einhängen). Er ist der einzige, der den Parent-Filter prüft. Taucht C in Backlog oder Blockers auf, greift `no:"Sub-issues progress"` nicht, und das Board wird sich mit Containern zusetzen, ohne je einen Fehler zu melden. Mit nur zwei Standalone-Issues sieht dagegen alles richtig aus, egal ob der Filter wirkt.

**Zuletzt die Automatik prüfen:** Issue A schließen und kontrollieren, dass es von selbst auf `Done` springt. Tut es das nicht, zeigt der Workflow „Item closed" aus Schritt 4 ins Leere, und die ganze `Closes #<nr>`-Kette funktioniert nicht.

Zeigt eine View das Falsche, **das jetzt merken, nicht in drei Wochen**, wenn das Board voll ist und niemand mehr weiß, welcher Filter falsch war.

Test-Issues danach schließen und auf `Rejected` setzen (gleich der erste sinnvolle Einsatz dieses Status).

## Schritt 10: Abschluss

Dem Nutzer melden: Board-Link, die vier Views, und die drei Dinge, die er wissen muss:

1. Der Sprint läuft automatisch weiter, GitHub verwaltet die Iterationen selbst.
2. `Rejected` ist da, um benutzt zu werden.
3. Ein Issue landet immer erst im `Backlog`. Auf `Ready` hebt es das Grooming, nicht der Anlegende.
