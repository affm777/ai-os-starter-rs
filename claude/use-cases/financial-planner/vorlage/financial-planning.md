# Liquiditätsplanung

Single Source of Truth. Klartext. Jede Zahl führt auf eine Annahme (`ANNAHMEN.md`) oder eine Quelle (Stripe/PayPal-Connector, `exporte/<quelle>/analysiert/`, `belege/analysiert/`) zurück. Der Skill `financial-planner` schreibt diese Datei fort.

> Noch keine Iteration gelaufen. Sobald Stripe/PayPal verbunden sind (oder ein Beleg in `belege/_neu/` liegt) und der Skill läuft, füllen sich die Abschnitte.

## Stand

_Datum des Laufs, Ingestion-Fenster und die Anker-Zerlegung: Bank-Kontostand (manuell, mit Stand-Datum) + Stripe-Saldo (live) + PayPal-Saldo (live) = **Cash heute**. Wird vom Skill gefüllt._

## Cockpit

_Cash heute, **Cash-out-Monat** (erster Forecast-Monat unter null, oder „reicht über den Horizont"), Einnahmen/Ausgaben des letzten vollen Monats, offene Posten. Wird vom Skill gefüllt._

## Vergangenheit (Fluss-Matrix)

_Die letzten 3 vollen Monate + laufender Monat bisher: je Einnahmestrom und Kostenblock eine Zeile, Netto-Cashflow je Monat. Bewusst KEINE Saldozeilen: die Kostenseite ist ohne Bank-Anbindung unvollständig, was passiert ist, steckt bereits im heutigen Kontostand. Wird vom Skill gefüllt._

## Forecast (Saldo-Kette ab heute)

_Rest des laufenden Monats + 6 Folgemonate. Je Monat: wiederkehrende Einnahmen (Fortschreibung), geplante Zuflüsse, Fixkosten, geplante Abflüsse, Netto, Endsaldo verkettet ab Cash heute. Jede Zeile trägt ihre Herkunft (`fixkosten` / `geplant` / `fortschreibung`). Wird vom Skill gefüllt._

## Buchungsjournal

_Der Drill-down: jede echte Buchung als Zeile (id, date, source, direction, stream/category, description, gross/fee/net, status). Zugleich die Herkunft der Fluss-Matrix und die Dedup-Grundlage (Abgleich über id beim nächsten Lauf). Nur Ist, keine Forecast-Pseudo-Buchungen. Wird vom Skill gefüllt._

## Zu prüfen

_Journalzeilen mit `status: offen` (uncategorized-Belege, unklare PayPal-Posten) plus überfällige Geplante Posten ohne Klärung. Wird vom Skill gefüllt._
