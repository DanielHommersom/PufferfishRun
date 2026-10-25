# US-27 — Diepte-label per zone (optioneel)
**Epic:** Extra · **Prio:** Could · **Omvang:** S

**Als** speler **wil ik** zien in welke diepte-zone ik zwem, **zodat** de zonewissel als mijlpaal voelt.

## Context
In `OceanBackground.swift` staan `setupDepthLabel()` en `updateDepthLabel()`, maar ze worden nooit aangeroepen — het label is dus nooit zichtbaar geweest.
- Teksten: `~ SHALLOW REEF ~` (score 0), `~ OPEN WATER ~` (10), `~ DEEP OCEAN ~` (25).
- 11 pt, wit 35%, rechts uitgelijnd op (w − 12, h − 50).
- Wissel: fade naar 0 (0.3 s), tekst wisselen, fade naar 0.35 (0.3 s).

## Acceptatiecriteria
- [ ] Label toont de juiste zone en wisselt mee met US-13.
- [ ] Botst niet met de mute-knop op (w−50, h−50) — originele positie overlapt die; verplaats naar linksonder of onder het score-label.
