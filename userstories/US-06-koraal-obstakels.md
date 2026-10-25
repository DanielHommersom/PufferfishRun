# US-06 — Koraalzuilen spawnen, bewegen en tekenen
**Epic:** Gameplay · **Prio:** Must · **Omvang:** L

**Als** speler **wil ik** koraalzuilen met een opening die van rechts naar links schuiven, **zodat** er een uitdaging is om doorheen te navigeren.

## Context (Swift — `GameScene.spawnObstacle`, `Obstacle.swift`)
**Spawnen** (elke `current_spawn_interval()` seconden, zie US-07):
```
gap    = current_gap_size()
margin = gap * 0.55
gap_y  = randf_range(gap/2 + margin, screen_h - gap/2 - margin)   # midden van de opening
x      = screen_w + 10
```
**Bewegen:** `x -= current_speed()` per tick. Verwijderen als `x < -100`.

**Tekenen** (per zuil, breedte `cw = 80`). Bovenzuil van y=0 tot `gap_y - gap/2`, onderzuil van `gap_y + gap/2` tot schermonder.
| Laag | Rect | Kleur |
|---|---|---|
| Basis | volle breedte | `(0.545, 0.102, 0.102)` |
| Lichte rand links | x 0–8 | `(0.647, 0.125, 0.125)` |
| Donkere rand rechts | x 70–80 | `(0.420, 0.063, 0.063)` |
| Horizontale lijnen | 1 px hoog, elke 12 px, alpha 0.2 | `(0.420, 0.063, 0.063)` |

- **Gekartelde rand** aan de kant van de opening: 20 blokjes van 4 px breed, hoogtes uit vast patroon `[8,4,12,4,8,12,4,8,4,12,8,4,12,8,4,4,12,8,4,8]`, steken uit de zuil de opening in. Daarachter een rij 2×2-pixeldetails (afwisselend basis/donker) net voorbij elk blokje.
- **Mos:** 8 blokjes (6×6 als `i % 3 == 0`, anders 4×4) op x = `i*10 + (i*7)%5`, y-jitter `(i*3)%8 − 4`, rond 16 px van de rand. Kleuren afwisselend `(0.176,0.541,0.243)` / `(0.267,0.667,0.333)`.
- **Bloemen:** alleen bij zuilhoogte > 60. Aantal: <100 → 1, <250 → 3, anders 5. Gelijk verdeeld over de hoogte, x = `20 + (i*23)%40`. Bloem = 6 bloemblaadjes (straal 5, zwarte rand 6) op afstand 9 rond een hart (straal 7, rand 8). Blaadje `(0.957,0.627,0.125)`, hart `(0.910,0.365,0.0)`.

## Acceptatiecriteria
- [ ] `Obstacle` scene (`Node2D`) met `gap_y`, `gap_size`, `passed: bool`, `top_rect()`, `bottom_rect()` in wereldcoördinaten.
- [ ] Getekend in `_draw()` één keer bij aanmaak (statisch, alleen positie verandert) — geen honderden child-nodes zoals in Swift.
- [ ] Alle patronen deterministisch (geen random) zodat elke zuil er hetzelfde uitziet als in het origineel.
- [ ] Zuilen spawnen rechts buiten beeld en verdwijnen links buiten beeld; geen geheugengroei na 5 minuten spelen.
- [ ] Eerste zuil spawnt direct bij start (Swift: `last_spawn_time = 0`, dus eerste update spawnt meteen).

## Notities
- `gap_y` is in Swift vanaf onder gemeten; de random-range is symmetrisch, dus in Godot gewoon vanaf boven gebruiken.
- Gebruik voor de tijd een eigen accumulator (`spawn_timer += delta`), niet de wandklok.
