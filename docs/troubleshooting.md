# Troubleshooting — AI Operating System Bootstrap

Bekannte Probleme und Lösungen für `bootstrap.sh` auf macOS.

---

## Bekannte macOS-Pitfalls

### Pitfall 1: Quarantine-Attribut blockiert Skript (ZIP-Download)

**Symptom:** macOS zeigt Dialog "Das Script kann nicht geöffnet werden, da der Entwickler nicht verifiziert werden kann" oder `Permission denied` beim Ausführen.

**Ursache:** Browser-Downloads bekommen automatisch das `com.apple.quarantine`-Attribut. Betrifft **nur ZIP-Downloads**, nicht `git clone`.

**Lösung:** Immer via `git clone` klonen:
```bash
git clone https://github.com/affm777/ai-os-starter-rs.git
```

Falls du trotzdem ein ZIP heruntergeladen hast:
```bash
xattr -dr com.apple.quarantine ./ai-os-starter-rs
```

---

### Pitfall 2: `Permission denied` bei `./bootstrap.sh`

**Symptom:** `bash: ./bootstrap.sh: Permission denied`

**Ursache:** Executable-Bit nicht gesetzt (sollte via git clone gesetzt sein, aber kann manchmal verloren gehen).

**Lösung:**
```bash
chmod +x bootstrap.sh
bash bootstrap.sh
```

---

### Pitfall 3: `claude: command not found`

**Symptom:** `claude --version` gibt Fehler, obwohl Claude Code installiert wurde.

**Ursache:** PATH wurde in der aktuellen Shell noch nicht neu geladen.

**Lösung:**
```bash
exec zsh        # neue zsh-Session mit frischem PATH
claude --version  # jetzt sollte es funktionieren
```

Falls `claude` immer noch nicht gefunden: Vollständige Terminal-Session schließen und neu öffnen.

Falls Claude Code gar nicht installiert ist: `curl -fsSL https://claude.ai/install.sh | bash` ausführen, dann Browser-OAuth auf claude.ai abschließen.

---

### Pitfall 4: zsh PATH in non-interaktivem Modus (Homebrew-Commands nicht gefunden)

**Symptom:** `bootstrap.sh` meldet `command not found: brew` obwohl Homebrew installiert ist.

**Ursache:** Bash-Skripte starten ohne `.zshrc` / `.zprofile` — Homebrew-PATH wird nicht gesourct.

**Erklärung:** `bootstrap.sh` enthält bereits den Fix: `eval "$(/opt/homebrew/bin/brew shellenv)"` am Anfang. Falls das Problem auftritt, ist Homebrew möglicherweise an einem anderen Ort installiert (z.B. Intel-Mac: `/usr/local/bin/brew`).

**Lösung:** In der Regel kein Problem, da `bootstrap.sh` Homebrew nicht benötigt. Nur relevant für `claude --version` Soft-Check — der ist als Warning implementiert und blockiert nicht.

---

## Claude-Code-Features

### `/remote-control` startet nicht

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

Danach Claude Code **neu starten**, die Änderung greift erst in einer neuen Session. Dann `/remote-control` erneut versuchen.

**Rückgängig machen:**
```bash
mv ~/.claude/settings.json.bak.remote-control ~/.claude/settings.json
```

**Was das für deine Privatsphäre bedeutet:** Telemetrie aus und Remote Control gleichzeitig geht technisch nicht, du musst dich entscheiden. Die übrigen drei Einträge (`DISABLE_ERROR_REPORTING`, `DISABLE_FEEDBACK_COMMAND`, `CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY`) bleiben aktiv. Die schalten nur Fehlerberichte und Umfragen ab, keine Features. Wenn du Remote Control nicht brauchst, lass das Flag einfach stehen.

---

### Routine in der Claude Desktop App scheitert am Zugriff auf den Second Brain

**Symptom:** Du hast in der **Claude Desktop App** eine Routine (Scheduled Task) angelegt, z.B. für `/brain:sync-meetings`. Das Anlegen klappt, aber beim Ausführen kommt ein Fehler, dass auf den Second-Brain-Ordner (`~/Documents/Second-Brain/`) nicht zugegriffen werden kann. **Im Terminal** (Claude Code über iTerm, das Terminal oder das Cursor-Terminal) läuft dieselbe Routine problemlos.

**Ursache (in >90 % der Fälle):** macOS schirmt Apps über sein Datenschutz-System (TCC) vom `~/Documents`-Ordner ab. Dein Terminal hat diesen Zugriff meist längst, die Claude Desktop App als eigenständige App aber noch nicht. Deshalb die Asymmetrie: Terminal ja, Desktop App nein.

**Erst prüfen, wo es klemmt:** Öffne das Terminal und führe aus:
```bash
ls ~/Documents/Second-Brain/01_Inbox/
```
- Listet Dateien auf → macOS selbst ist nicht das Problem, es fehlt der Desktop-App der Zugriff. Weiter mit **Fix 1**.
- `Permission denied` → auch dein Terminal hat keinen Zugriff. Dann greift **Fix 1** trotzdem, nur für das Terminal-Programm statt für die Claude-App.

#### Fix 1: Der Claude Desktop App Festplattenzugriff geben (Regelfall)

1. **Systemeinstellungen** öffnen (Apfel-Menü oben links).
2. Links **Datenschutz & Sicherheit** wählen.
3. Zum Punkt **Vollständiger Festplattenzugriff** (Full Disk Access) scrollen und öffnen.
4. Das **Plus (+)** klicken (ggf. vorher unten links per Passwort/Touch ID entsperren).
5. Unter `/Programme` **Claude** auswählen und hinzufügen. Der Schalter daneben muss **an** sein.
6. Die Claude Desktop App **komplett beenden und neu starten** (Cmd+Q, nicht nur Fenster schließen).
7. Routine erneut mit **„Run now"** testen.

Wer keinen vollen Festplattenzugriff geben will: Statt Schritt 3 den Punkt **Dateien und Ordner** wählen und der Claude App dort gezielt den Ordner **Dokumente** freigeben. Full Disk Access ist aber der zuverlässigere Weg.

#### Fix 2: Zugriffsrecht in der Routine erlauben (falls Fix 1 nicht reicht)

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

## Recovery-Szenarien

### "Wo finde ich meine Backup-Files?"

Alle `.bak.<timestamp>`-Files auf einen Blick:
```bash
ls ~/.claude/*.bak.* 2>/dev/null
ls ~/.claude/**/*.bak.* 2>/dev/null
```

Oder mit `find`:
```bash
find ~/.claude -name "*.bak.*" 2>/dev/null
```

---

### "Wie merge ich mein altes CLAUDE.md mit dem neuen?"

```bash
# Unterschiede anzeigen
diff ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.bak.<TIMESTAMP>
```

Eigene Custom-Anweisungen aus dem `.bak`-File identifizieren und manuell in das neue `CLAUDE.md` einfügen. Dann `.bak`-Datei löschen oder behalten.

Alternativ: Das Backup als "dein Custom" behandeln und das neue als "Workshop-Basis":
```bash
# Zeige was NEU im Repo ist (was Bootstrap hat, was dein Custom nicht hatte)
diff ~/.claude/CLAUDE.md.bak.<TIMESTAMP> ~/.claude/CLAUDE.md
```

---

### "Mein Vault liegt nicht unter `~/Documents/Second-Brain/`"

Zwei Optionen:

**Option A (empfohlen): Symlink erstellen** — BEVOR bootstrap.sh ausführen:
```bash
ln -s /pfad/zu/meinem/vault ~/Documents/Second-Brain
bash bootstrap.sh  # jetzt in deinen Vault-Pfad installiert
```

**Option B: Manuell kopieren:**
```bash
cp -r ~/Desktop/projects/ai-os-starter-rs/vault-skeleton/* /pfad/zu/meinem/vault/
```

---

### "Das Skript ist mittendrin abgebrochen"

Kein Problem — einfach nochmal ausführen:
```bash
bash bootstrap.sh
```

`bootstrap.sh` ist **idempotent**: bereits korrekte Files werden übersprungen (Unchanged-Meldung), nur fehlende werden ergänzt. Du verlierst keine bereits kopierten Files.

---

### "Ich will alles rückgängig machen"

**Schritt 1: Backup-Files einspielen** (falls vorhanden):
```bash
# Alle Backups eines bestimmten Timestamps zurückspielen
for f in ~/.claude/*.bak.<TIMESTAMP>; do mv "$f" "${f%.bak.*}"; done
```

**Schritt 2: Vault-Changes rückgängig machen** (falls neue Vault-Files nicht gewollt):
```bash
# Templates die Bootstrap angelegt hat (wenn du vorher keine hattest)
rm ~/Documents/Second-Brain/00_Meta/system/vault-index.md 2>/dev/null
rm ~/Documents/Second-Brain/00_Meta/system/vault-log.md 2>/dev/null
rm ~/Documents/Second-Brain/00_Meta/clusters/vault-clusters.md 2>/dev/null
# Templates einzeln entfernen falls nötig
```

**Schritt 3 (Nuklear-Option):** `~/.claude/` komplett löschen — NUR wenn du vor Bootstrap kein Claude Code Setup hattest:
```bash
rm -rf ~/.claude/  # ACHTUNG: löscht alles, nur wenn du dir sicher bist
```

---

### "settings.json hat keine Hooks aktiv"

Das ist normal — `bootstrap.sh` überschreibt `settings.json` NICHT wenn sie bereits existiert.

**Diagnose:** Prüfe den Unterschied:
```bash
diff ~/.claude/settings.json ~/.claude/settings.json.template
```

**Lösung:** Hooks-Block aus Template manuell übernehmen. Den `hooks`-Key aus `settings.json.template` in deine `settings.json` einfügen.

Alternativ: Settings sichern und Template als Basis nehmen:
```bash
cp ~/.claude/settings.json ~/.claude/settings.json.bak.manual
cp ~/.claude/settings.json.template ~/.claude/settings.json
```

Dann deine persönlichen Anpassungen (permissions.allow, mcpServers, etc.) aus dem Backup in die neue Datei übertragen.

---

## Noch ein Problem?

Falls keine der obigen Lösungen hilft: Vollständigen Terminal-Output (`bash bootstrap.sh` und die Fehlermeldung) an Affom schicken.
