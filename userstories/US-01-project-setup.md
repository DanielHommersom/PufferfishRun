# US-01 — Project-setup, viewport en constanten
**Epic:** Fundament · **Prio:** Must · **Omvang:** S

**Als** ontwikkelaar **wil ik** een Godot-project dat qua schermformaat, oriëntatie en tick-rate gelijk staat aan de Swift-versie, **zodat** alle overgezette waarden zonder omrekenen kloppen.

## Context (Swift)
- Portrait-only, fullscreen, statusbalk verborgen (`Info.plist`, `ContentView.statusBar(hidden:)`).
- Scene-grootte = `UIScreen.main.bounds.size`, `scaleMode = .aspectFill`.
- Alle waarden in `Constants.swift` + `SkinDefinition.swift`.

## Acceptatiecriteria
- [ ] `project.godot`: viewport 393×852, `display/window/handheld/orientation = portrait`, stretch `canvas_items` / `expand` (staat al).
- [ ] `physics/common/physics_ticks_per_second = 60`, `physics/common/max_physics_steps_per_frame` default.
- [ ] Achtergrond-clearcolor `Color(0.04, 0.16, 0.29)`.
- [ ] `res://scripts/constants.gd` met minimaal:

| Constante | Waarde | Eenheid |
|---|---|---|
| FISH_BASE_RADIUS | 18 | px |
| FISH_MAX_INFLATE | 14 | – |
| INFLATE_SPEED | 0.35 | per tick |
| DEFLATE_SPEED | 0.18 | per tick |
| GRAVITY | 0.22 | px/tick² |
| MAX_VEL | 5.0 | px/tick (beide richtingen) |
| GAP_SIZE_INITIAL / MIN | 230 / 120 | px |
| OBSTACLE_SPEED_INITIAL / MAX | 2.5 / 4.0 | px/tick |
| OBSTACLE_WIDTH | 80 | px (zie bevinding B1) |
| SPAWN_INTERVAL_INITIAL / MIN | 2.5 / 1.5 | s |
| DIFFICULTY_RAMP_SPEED / GAP / SPAWN | 25 / 40 / 35 | score |
| ENEMY_MIN_SCORE jelly / shark / urchin | 5 / 15 / 25 | score |
| ENEMY_SPAWN_INTERVAL | 3.2 | s |
| ENEMY_SPAWN_CHANCE | 0.45 | kans |

- [ ] Gedeelde kleuren: `OCEAN_TOP (0.04,0.16,0.29)`, `CORAL_BASE (0.545,0.125,0.125)`, `CORAL_HIGHLIGHT (0.690,0.188,0.188)`, `UI_ORANGE (0.957,0.659,0.196)`, `UI_BLUE (0.102,0.290,0.416)`, `UI_GREEN (0.267,0.800,0.267)`, `UI_GOLD_TEXT (1.0,0.867,0.533)`, `UI_MUTED_TEXT (0.533,0.667,0.733)`, `PANEL_BG (0.039,0.165,0.290)`.
- [ ] Gebundelde monospace bold font als project-default `Theme` (Courier New is niet vrij te bundelen; gebruik bv. Courier Prime Bold, OFL).
- [ ] Mappenstructuur: `scenes/`, `scripts/`, `assets/fonts/`, `assets/audio/`, `assets/images/`.

## Notities
- Test op een klein (SE, 375×667) en groot (Pro Max, 440×956) scherm: `expand` geeft extra ruimte; alles moet relatief tot `viewport size` gelayout worden.
