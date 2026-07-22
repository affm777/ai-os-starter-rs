# Troubleshooting — AI Operating System

Die zwei häufigsten Stolpersteine, jeweils mit Diagnose und Fix.

---

## 1) Routine in der Claude Desktop App scheitert am Zugriff auf den Second Brain

**Symptom:** Du hast in der **Claude Desktop App** eine Routine (Scheduled Task) angelegt, z.B. für `/brain:sync-meetings`. Das Anlegen klappt, aber beim Ausführen kommt ein Fehler, dass auf den Second-Brain-Ordner (`~/Documents/Second-Brain/`) nicht zugegriffen werden kann. **Im Terminal** (Claude Code über iTerm, das Terminal oder das Cursor-Terminal) läuft dieselbe Routine problemlos.

**Ursache (in >90 % der Fälle):** macOS schirmt Apps über sein Datenschutz-System (TCC) vom `~/Documents`-Ordner ab. Dein Terminal hat diesen Zugriff meist längst, die Claude Desktop App als eigenständige App aber noch nicht. Deshalb die Asymmetrie: Terminal ja, Desktop App nein.

**Erst prüfen, wo es klemmt:** Öffne das Terminal und führe aus:
```bash
ls ~/Documents/Second-Brain/01_Inbox/
```
- Listet Dateien auf → macOS selbst ist nicht das Problem, es fehlt der Desktop-App der Zugriff. Weiter mit **Fix 1**.
- `Permission denied` → auch dein Terminal hat keinen Zugriff. Dann greift **Fix 1** trotzdem, nur für das Terminal-Programm statt für die Claude-App.

### Fix 1: Der Claude Desktop App Festplattenzugriff geben (Regelfall)

1. **Systemeinstellungen** öffnen (Apfel-Menü oben links).
2. Links **Datenschutz & Sicherheit** wählen.
3. Zum Punkt **Vollständiger Festplattenzugriff** (Full Disk Access) scrollen und öffnen.
4. Das **Plus (+)** klicken (ggf. vorher unten links per Passwort/Touch ID entsperren).
5. Unter `/Programme` **Claude** auswählen und hinzufügen. Der Schalter daneben muss **an** sein.
6. Die Claude Desktop App **komplett beenden und neu starten** (Cmd+Q, nicht nur Fenster schließen).
7. Routine erneut mit **„Run now"** testen.

Wer keinen vollen Festplattenzugriff geben will: Statt Schritt 3 den Punkt **Dateien und Ordner** wählen und der Claude App dort gezielt den Ordner **Dokumente** freigeben. Full Disk Access ist aber der zuverlässigere Weg.

### Fix 2: Zugriffsrecht in der Routine erlauben (falls Fix 1 nicht reicht)

Wenn der Terminal-Test oben Dateien anzeigt, aber die Routine nach Fix 1 immer noch scheitert, fehlt der Routine die Erlaubnis, außerhalb des Projektordners zu schreiben:

1. In der Desktop App **Routines** öffnen, die Task auswählen, **Edit**.
2. **Permission Mode** von „Ask" auf **„Accept Edits"** stellen, speichern.
3. Alternativ die Task einmal mit **„Run now"** starten und bei den Nachfragen jeweils „Yes, don't ask again" wählen.

Als manuelle Variante kannst du dem Second Brain in `~/.claude/settings.json` unter `permissions.allow` explizit Zugriff geben:
```json
"permissions": {
  "allow": [
    "Read(~/Documents/Second-Brain/**)",
    "Edit(~/Documents/Second-Brain/**)"
  ]
}
```
Danach die Desktop App neu starten.

---

## 2) `/remote-control` startet nicht

**Symptom:** `/remote-control` lässt sich nicht ausführen, obwohl Claude Code aktuell ist und du eingeloggt bist. Das Slash-Command-Menü nennt keinen Grund.

**Ursache:** Der Eintrag `"DISABLE_TELEMETRY": "1"` im `env`-Block von `~/.claude/settings.json` schaltet nicht nur die Telemetrie ab, sondern auch die Feature-Flag-Auswertung. Remote Control prüft seine Verfügbarkeit über genau diese Feature-Flags und verweigert deshalb den Start.

Der Starter liefert dieses Flag **nicht mehr** aus. Relevant ist der Abschnitt also nur, wenn du es selbst gesetzt hast oder aus einem älteren Setup mitbringst.

**Diagnose (optional):** Der direkte CLI-Aufruf nennt die Ursache im Klartext, das Slash-Command nicht:
```bash
claude remote-control --help
```

**Quick-Fix:** Diesen Block komplett kopieren und im Terminal ausführen. Er entfernt nur `DISABLE_TELEMETRY`, legt vorher ein Backup an und lässt alles andere unangetastet:
```bash
python3 - <<'EOF'
import json, pathlib, shutil
p = pathlib.Path.home() / ".claude" / "settings.json"
d = json.loads(p.read_text())
if d.get("env", {}).pop("DISABLE_TELEMETRY", None) is None:
    print("DISABLE_TELEMETRY war nicht gesetzt. Nichts geändert.")
else:
    shutil.copy(p, str(p) + ".bak.remote-control")
    p.write_text(json.dumps(d, indent=2, ensure_ascii=False) + "\n")
    print("DISABLE_TELEMETRY entfernt. Backup: ~/.claude/settings.json.bak.remote-control")
EOF
```

Alternativ ohne Terminal: gib Claude einfach die Anweisung „Bitte entferne den Eintrag `DISABLE_TELEMETRY` aus meiner `~/.claude/settings.json` und starte neu."

Danach Claude Code **neu starten**, die Änderung greift erst in einer neuen Session. Dann `/remote-control` erneut versuchen.

**Rückgängig machen:**
```bash
mv ~/.claude/settings.json.bak.remote-control ~/.claude/settings.json
```

**Was das für deine Privatsphäre bedeutet:** Telemetrie aus und Remote Control gleichzeitig geht technisch nicht, du musst dich entscheiden. Die übrigen drei Einträge (`DISABLE_ERROR_REPORTING`, `DISABLE_FEEDBACK_COMMAND`, `CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY`) bleiben aktiv. Die schalten nur Fehlerberichte und Umfragen ab, keine Features. Wenn du Remote Control nicht brauchst, lass das Flag einfach stehen.

---

## Noch ein Problem?

Falls keine der obigen Lösungen hilft: Vollständigen Terminal-Output (`bash bootstrap.sh` und die Fehlermeldung) an Affom schicken.
