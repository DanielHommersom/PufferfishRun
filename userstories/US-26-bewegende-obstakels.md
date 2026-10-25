# US-26 — Bewegende koraalzuilen (optioneel)
**Epic:** Extra · **Prio:** Could · **Omvang:** S

**Als** gevorderde speler **wil ik** zuilen waarvan de opening op en neer beweegt, **zodat** hoge scores extra uitdagend blijven.

## Context
Volledig gecodeerd in de Swift-versie maar **uitgezet** (`shouldMove = false // for stability`). Logica die klaarstaat:
- Kans op bewegende zuil: 0 onder score 8; daarna `0.55 * min((score - 8) / 25, 1)`.
- Bewegingssnelheid: `1.2 + (2.4 - 1.2) * min(score / 25, 1)` px/tick.
- Opening beweegt `± move_range` rond `gap_y`, keert om bij de grens, en wordt geclampt op `gap/2 + 40` … `h - gap/2 - 40`.
- `move_range` wordt in de code nergens bepaald (altijd 0) — moet gekozen worden.

## Acceptatiecriteria
- [ ] Achter een feature-flag in `Constants.gd` (default uit = pariteit met v1.0).
- [ ] In Godot alleen de y-offset van de twee zuildelen verschuiven, niet hertekenen (dat was waarschijnlijk de instabiliteit in Swift: `removeAllChildren()` + volledig hertekenen per frame).
- [ ] Hitboxen bewegen mee.
- [ ] `move_range` vastgesteld na playtest (startvoorstel: 60 px).
