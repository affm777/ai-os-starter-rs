# Annahmen

Jede Geschäfts-Annahme, die in die Planung einfließt, steht hier: eine pro Zeile, im Klartext, mit Quelle. Keine Annahme versteckt sich in einer Formel. Ändert sich eine Annahme, ändert sich diese Zeile, und der Diff zeigt es.

## Konfiguration

Diese Version ist eine **reine Liquiditätsplanung** nach dem Anker-Modell: Cash heute, davon vorwärts. Nur die Werte, die dafür nötig sind:

- `waehrung: EUR` — die Hauptwährung. Beträge in anderer Währung werden zum jeweiligen Betrag geführt und im Report gekennzeichnet.
- `bank_kontostand: <offen>` — der aktuelle Stand des Bankkontos **plus etwaiger weiterer nicht angebundener Konten** (Zweitkonto, Sparkonto, Kasse), als eine Summe. Diese Konten sind nicht angebunden, deshalb ist der Wert **manuell**: der Skill fragt ihn **zu Beginn jedes Laufs** kurz ab (Schnell-Bestätigung, wenn unverändert; Stripe/PayPal kommen automatisch). In der Excel ist er die gelbe Eingabezelle.
- `stand_datum: <offen>` — von wann der Wert ist. Wird bei jeder Anker-Frage mit aktualisiert.

## Der Anker (gegen Doppelzählung, in drei Sätzen)

Cash heute = `bank_kontostand` + Stripe-Saldo (live) + PayPal-Saldo (live). Alles, was je passiert ist, steckt bereits in diesen drei Zahlen, auch schon erhaltene Investment-Tranchen. Nur **künftige** Zu- und Abflüsse stehen unten als Fixkosten oder Geplante Posten, damit nichts doppelt zählt.

## Fixkosten (Verträge, wiederkehrend)

Was regelmäßig und sicher rausgeht. Diese Tabelle ist die Basis der Forecast-Kostenseite: der Skill schreibt jede Zeile je Rhythmus in die kommenden Monate fort. Einmal grob vollständig anlegen (macht der Skill beim ersten Lauf mit dir), danach nur pflegen, wenn sich ein Vertrag ändert. Sieht der Skill in den Quellen einen wiederkehrenden Posten, der hier fehlt, schlägt er die Aufnahme vor.

| Posten | Betrag | Rhythmus | Nächste Fälligkeit | Kostenblock | Quelle / seit |
|---|--:|---|---|---|---|
| _(Beispiel) Gehälter inkl. Nebenkosten_ | _3.500,00_ | _monatlich_ | _2026-07-31_ | _personal_ | _Lohnabrechnung, seit 2026-05_ |
| _(Beispiel) Hosting & SaaS_ | _39,00_ | _monatlich_ | _2026-08-01_ | _software-it_ | _Rechnungen Hoster_ |

## Geplante Posten (einmalig, terminiert)

Was terminiert noch kommt, rein oder raus: erwartete Rechnungen, angekündigte Kapital-Tranchen, bekannte Einmalabbuchungen. Auch offene sevDesk-Rechnungen mit Fälligkeit landen hier (schlägt der Skill vor). **Zwischendurch vormerken geht ohne vollen Lauf:** sag Claude einfach "merk dir: in 3 Wochen kommt eine Rechnung über 300 Euro", er trägt die Zeile hier ein.

Lifecycle: Status `offen`, bis der Posten passiert ist. Taucht die passende echte Buchung in den Quellen auf, setzt der Skill den Status auf `erledigt` (mit Buchungs-id), damit nichts doppelt zählt. Überfällige offene Posten fragt der Skill aktiv nach (verschieben, streichen oder als über die Bank gelaufen abhaken).

| Datum | Betrag | Richtung | Beschreibung | Kostenblock / Strom | Status |
|---|--:|---|---|---|---|
| _(Beispiel) 2026-08-21_ | _300,00_ | _aus_ | _Agentur-Rechnung Redesign_ | _fremdleistungen_ | _offen_ |
| _(Beispiel) 2026-09-01_ | _50.000,00_ | _ein_ | _VC-Tranche 2_ | _kapital_ | _offen_ |

## Aktiv

- (Beispiel) Software-Kosten (Hosting, SaaS) laufen als fixer Block ca. konstant weiter — Quelle: bisherige Belege — seit: 2026-07-21
- (Beispiel) Wiederkehrende Einnahmen werden als Durchschnitt der letzten 3 vollen Monate fortgeschrieben — Quelle: Skill-Default, hier überschreibbar — seit: 2026-07-21

## Offene Fragen (noch keine Annahme, aber gebraucht)

- Aktueller Bank-Kontostand (+ Datum)?
- Welche laufenden Verträge gehören in die Fixkosten-Tabelle?
- Gibt es schon bekannte künftige Einmalposten (Rechnungen, Kapital-Tranchen)?
