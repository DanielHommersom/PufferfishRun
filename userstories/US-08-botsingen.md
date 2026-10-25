# US-08 — Botsingen en schermranden
**Epic:** Gameplay · **Prio:** Must · **Omvang:** S

**Als** speler **wil ik** dat ik af ben bij het raken van koraal, vijanden of de boven-/onderrand, **zodat** fouten consequenties hebben.

## Context (Swift — `GameScene.update`)
Geen physics-engine; handmatige checks elk frame in deze volgorde:
1. **Rand:** `fish.y - r < 0` of `fish.y + r > screen_h` → game over.
2. **Koraal:** cirkel (vis, straal `get_radius()`) vs rechthoek, voor boven- én onderzuil:
   ```
   near = Vector2(clamp(c.x, rect.x0, rect.x1), clamp(c.y, rect.y0, rect.y1))
   hit  = c.distance_squared_to(near) < r * r
   ```
   Zuilrechthoeken zijn de **platte** zuil (80 breed); de gekartelde rand en bloemen tellen niet mee.
3. **Vijand:** cirkel vs cirkel, `distance < fish_r + enemy_r - 4` (4 px vergevingsmarge).

## Acceptatiecriteria
- [ ] Zelfde wiskundige checks, geen `Area2D`/physics-bodies (deterministisch en identiek aan origineel).
- [ ] Hitbox groeit mee met opblazen (straal 18 → 29.9).
- [ ] Eerste hit roept `trigger_game_over()` precies één keer aan (guard).
- [ ] Debug-toggle (alleen in debug-build) die hitboxen tekent.

## Notities
- Omdat de gekartelde rand 4–12 px de opening in steekt maar geen hitbox heeft, voelt het spel iets vergevingsgezinder dan het eruitziet. Bewust zo laten voor pariteit.
