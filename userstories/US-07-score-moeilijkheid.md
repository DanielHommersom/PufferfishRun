# US-07 — Score en moeilijkheidscurve
**Epic:** Gameplay · **Prio:** Must · **Omvang:** S

**Als** speler **wil ik** punten scoren per gepasseerde zuil en dat het spel geleidelijk moeilijker wordt, **zodat** er progressie en spanning is.

## Context (Swift — `GameScene`)
- **Score +1** zodra `obstacle.x + 80 < fish.x` en `!passed`; daarna `passed = true`.
- Bij elke scorewijziging: `ocean_background.update(score)` (US-13).

Lineaire interpolatie met `t = min(score / ramp, 1)`:
| Waarde | Start | Eind | Ramp (score) |
|---|---|---|---|
| Opening (`gap`) | 230 px | 120 px | 40 |
| Snelheid | 2.5 px/tick | 4.0 px/tick | 25 |
| Spawn-interval | 2.5 s | 1.5 s | 35 |

## Acceptatiecriteria
- [ ] Functies `current_gap_size()`, `current_speed()`, `current_spawn_interval()` in de game-scene of een `Difficulty`-helper, met bovenstaande formules.
- [ ] Score-label: midden boven, 80 px vanaf de bovenkant, 36 pt, wit, monospace bold, z boven alles behalve UI-knoppen. Start op "0".
- [ ] Score telt nooit dubbel voor dezelfde zuil.
- [ ] Unit-test (GUT of eenvoudige assert-scene): score 0 → 230/2.5/2.5; score 20 → 175/3.7/1.93; score ≥40 → 120/4.0/1.5.
