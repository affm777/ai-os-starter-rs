# Kostenblöcke

Die Kostenblöcke für die Liquiditätsplanung, also die Ausgaben-Seite. Der Skill ordnet jeden Beleg aus `belege/_neu/` und jede Ausgabe aus den Quellen genau einem Block hier zu. Es geht nur um Cash: was fließt raus und wofür.

> Das ist ein **Vorschlag**, kein Gesetz. Blöcke frei umbenennen, ergänzen oder streichen, so wie es zu deinem Geschäft passt. Der Skill arbeitet mit dem, was hier steht.

## Zuordnungs-Regeln (PFLICHT)

1. **Genau ein Kostenblock pro Posten.** Zuordnung erfolgt aus Händler-String, Betrag und Datum.
2. **Confidence-Schwelle 0.85.** Ist der Skill sich nicht sicher (Signal reicht nicht, z.B. Händler „Acme Corp", 500 EUR, kein Kontext), wird der Posten `uncategorized` gesetzt und am Ende via Rückfrage geklärt („zu prüfen"-Queue). Nicht raten.
3. **Menschliche Namen** (z.B. „Max Mustermann Design") und Freelancer-Plattformen (Upwork, Fiverr) gehen nach `fremdleistungen`, nicht nach `personal`. `personal` nur bei echten Gehaltsläufen.
4. **Herkunft:** Jeder zugeordnete Posten trägt in `financial-planning.md` seinen Block-Slug und die Quelldatei.

## Blöcke

| Kostenblock | Slug | Was rein gehört | Fix/Var |
|---|---|---|---|
| Software & IT | `software-it` | SaaS, Hosting, Domains, Cloud, Dev-Tools (AWS, GitHub, Notion, Vercel) | fix |
| Marketing & Werbung | `marketing` | Digitale Ads (Google, Meta), PR, Event-Sponsoring | var |
| Fremdleistungen | `fremdleistungen` | Freelancer, Agenturen, externe Entwickler/Berater | var |
| Recht & Beratung | `recht-beratung` | Steuerberater, Anwälte, Notare, Compliance | fix |
| Reise & Transport | `reise` | Flüge, Bahn, Hotels, Ride-Sharing | var |
| Büro & Hardware | `buero-hardware` | Laptops, Monitore, Büromaterial | beides |
| Bank- & Finanzgebühren | `finanzgebuehren` | Stripe-Gebühren, PayPal-Gebühren, Kontoführung, Sollzinsen | var |
| Personal & Sozial | `personal` | Echte Gehaltsläufe inkl. Lohnnebenkosten | fix |
| Steuern | `steuern` | Abflüsse an Finanzamt/Bundeskasse (USt-Vorauszahlung, ESt, GewSt) | var |
| Privatentnahme | `privatentnahme` | Überweisungen aufs Privatkonto (Einzelunternehmer). Kein Aufwand, mindert nur Liquidität | - |
| Nicht zugeordnet | `uncategorized` | Fallback bei Confidence < 0.85. Löst Rückfrage aus | - |

## Regeln für neue Blöcke

- **`uncategorized` ist kein Endzustand.** Am Ende jedes Laufs als Rückfrage auflisten: „Beleg X (Betrag, Datum, Empfänger) passt in keinen Block, welchem zuordnen, oder neuen Block anlegen?"
- **Neue Blöcke** nur nach Bestätigung, dann als Zeile hier eintragen. Der Skill legt keine Kategorien eigenmächtig an.
