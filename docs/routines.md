# Routines — dein AI OS läuft ohne dich

Routines sind Aufgaben, die Claude zu festen Zeiten **automatisch auf deinem Rechner** ausführt. Du legst sie einmal an, danach halten sie deinen Second Brain in Ordnung, ohne dass du etwas tust.

Drei Routines empfehlen wir zum Start. Sie bauen aufeinander auf: die erste füllt den Posteingang, die zweite räumt ihn auf, die dritte prüft einmal pro Woche, ob alles heil ist.

---

## Wichtig zuerst: Desktop App, nicht Cowork

Routines gibt es an zwei Stellen, und nur eine davon funktioniert für diese drei Aufgaben.

| | Wo es läuft | Zugriff auf deine Skills und den Vault |
|---|---|---|
| **Routines in der Desktop App** | dein Rechner | ja, vollständig |
| **Cloud-Routines (Cowork)** | Anthropic-Server | nein |

Die drei Routines unten rufen alle einen `/brain:`-Skill auf und schreiben in deinen lokalen Vault. In der Cloud gibt es beides nicht. Eine dort angelegte Routine schlägt fehl, und zwar auf eine verwirrende Art: Der Fehler sieht aus wie ein kaputter Skill, ist aber nur der falsche Ort.

**Also immer: Claude Desktop App → Routines → New routine → Local.**

Der Rechner muss zur geplanten Zeit laufen und die App offen sein. Schaltet sich der Laptop schlafen, pausiert die Routine. In der Übersicht gibt es dafür einen „Aktiv halten"-Schalter.

---

## Routine 1 — Meetings in den Second Brain

Holt neue Meetings aus Fathom, schreibt sie als strukturierte Notiz in deinen Posteingang und verlinkt automatisch die beteiligten Personen und das passende Projekt.

**Voraussetzung:** Fathom als Connector verbunden, siehe [connector-setup.md](connector-setup.md).

**Name**
```
fathom-sync
```

**Description**
```
Täglicher autonomer Fathom-Sync: neue Meetings aus Fathom MCP nach Obsidian-Vault 01_Inbox/, mit Personen-Cross-Linking und Projekt-Matching.
```

**Instructions**
```
/brain:sync-meetings scheduled
```

**Empfohlener Zeitplan:** täglich, früh morgens (z. B. 06:00). Dann liegt die Nachbereitung von gestern schon da, wenn du den Rechner aufklappst.

---

## Routine 2 — Posteingang einsortieren

Nimmt alles, was sich in `01_Inbox/` angesammelt hat, und legt es an den richtigen Ort: zum Projekt, zur Area, zu den Resources oder den Kontakten. Aktualisiert dabei den Index und die Timeline.

**Name**
```
inbox-sort
```

**Description**
```
Täglicher autonomer Inbox-Sweep im Second Brain.
```

**Instructions**
```
/brain:sort-inbox scheduled
```

**Empfohlener Zeitplan:** täglich, abends. So läuft das Einsortieren nach getaner Arbeit und nicht mitten hinein.

---

## Routine 3 — Wöchentlicher Health-Check

Prüft den ganzen Vault auf Index-Drift, kaputte Wikilinks, fehlende Cross-Referenzen, verwaiste Dateien und veraltete Decisions. Schreibt einen Bericht, ändert aber nichts von selbst.

**Name**
```
vault-health
```

**Description**
```
Wöchentlicher Vault-Health-Check: prüft Index-Drift, kaputte Wikilinks, fehlende Cross-Referenzen, verwaiste Dateien und veraltete Decisions.
```

**Instructions**
```
/brain:health-check scheduled
```

**Empfohlener Zeitplan:** wöchentlich, z. B. Sonntagabend oder Montagfrüh.

Der Report landet unter `00_Meta/system/lint-reports/`. Bewusst nur Befund, keine automatischen Korrekturen: Was repariert wird, entscheidest du.

---

## So legst du eine Routine an

1. Claude Desktop App öffnen
2. In der Seitenleiste auf **Routines**
3. **New routine** → **Local** wählen
4. **Name** kopieren und einsetzen
5. **Description** kopieren und einsetzen
6. **Instructions** kopieren und einsetzen
7. **Working folder** setzen, falls die Routine ein bestimmtes Projekt braucht
8. **Schedule** wählen
9. Speichern, dann **„Aktiv halten"** in der Übersicht einschalten

Jedes Feld hat oben einen eigenen Kopier-Block. Du kopierst also dreimal einzeln, statt einen Sammelblock auseinanderzupflücken.

Beim ersten Lauf fragt Claude nach Berechtigungen. Bestätige sie einmal dauerhaft, sonst bleibt die Routine beim nächsten unbeaufsichtigten Lauf hängen.

---

## Prüfen, ob es läuft

Die Routine schreibt ihren Lauf in `00_Meta/system/vault-log.md` mit. Eine Zeile pro Durchgang. Wenn dort nach dem ersten geplanten Zeitpunkt nichts steht, lief sie nicht.

Häufigste Ursachen, in dieser Reihenfolge:

1. Routine in Cowork statt in der Desktop App angelegt
2. Laptop war zur geplanten Zeit zu, „Aktiv halten" nicht eingeschaltet
3. Berechtigungen beim ersten Lauf nicht dauerhaft bestätigt
4. Connector abgelaufen — bei Fathom hilft neu verbinden

---

## Wo die Routines auf der Festplatte liegen

```
~/.claude/scheduled-tasks/<name>/SKILL.md
```

Dort stehen `name`, `description` und der auszuführende Befehl. Du kannst die Datei direkt bearbeiten, die Änderung greift beim nächsten Lauf.

Was **nicht** in dieser Datei steht: Zeitplan, Modell, Berechtigungsmodus und ob die Routine aktiv ist. Das verwaltet die App separat. Ein Backup dieser Datei allein stellt eine Routine also nicht wieder her.
