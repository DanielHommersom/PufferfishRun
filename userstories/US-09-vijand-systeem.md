# US-09 — Vijand-spawner en basisgedrag
**Epic:** Gameplay · **Prio:** Must · **Omvang:** M

**Als** speler **wil ik** dat er vanaf een bepaalde score vijanden verschijnen, **zodat** het spel afwisselender en lastiger wordt dan alleen zuilen ontwijken.

## Context (Swift — `GameScene.maybeSpawnEnemy`, `Enemy.swift`)
- Elke **3.2 s** een spawn-poging; slaagt met kans **0.45**.
- Beschikbare types op basis van huidige score:
  | Type | Vanaf score |
  |---|---|
  | Kwal | 5 |
  | Haai | 15 |
  | Zee-egel | 25 |
- Type = uniform random uit de beschikbare types (dus vanaf 25: elk 1/3).
- Elke vijand: eigen `time += 0.04` per tick, beweegt naar links, `is_dead = true` als `x < -100` → verwijderen.
- Vijanden zitten op z-index 4 (boven zuilen, onder de vis/score).
- Bij game over worden alle vijanden **direct** verwijderd (niet geanimeerd).

## Acceptatiecriteria
- [ ] Basisscene `Enemy` (`Node2D`) met `enemy_type`, `radius`, `time`, `base_y`, `is_dead`, virtuele `update_motion()` en `_draw()`; drie subklassen of één script met `match` (US-10/11/12).
- [ ] Spawner in de game-scene met eigen timer (3.2 s) en kans 0.45; geen spawn na game over.
- [ ] Botsing via US-08 (cirkel-cirkel, −4 px).
- [ ] Debug-optie om een specifiek vijandtype te forceren.

## Notities
- Swift start de enemy-timer op 0 net als de zuilen, dus de eerste poging gebeurt direct — maar dan is de score nog < 5, dus effectief na de eerste poging ná score 5.
