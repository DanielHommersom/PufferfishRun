# US-05 — Kogelvis tekenen en animeren
**Epic:** Gameplay · **Prio:** Must · **Omvang:** M

**Als** speler **wil ik** een levendige vis die zichtbaar opzwelt, stekels krijgt en van kleur verandert, **zodat** ik direct zie hoe ver ik ben opgeblazen.

## Context (Swift — `PufferFish.redraw`)
Alles is vector, opnieuw getekend elk frame op basis van `r = get_radius()`. **y-waarden hieronder zijn al gespiegeld voor Godot.**

| Onderdeel | Vorm (lokaal, Godot) | Kleur |
|---|---|---|
| Staart | driehoek (-1.1r, -0.55r+w), (-1.1r, 0.55r+w), (-1.7r, w); outline 3 px zwart | `skin.tail` |
| Lichaam | ellips, halve assen 1.15r × 1.0r, outline 3 px zwart | `skin.body`, donkerder bij opblazen |
| Buik | ellips center (0.1r, 0.425r), halve assen 0.7r × 0.425r, alpha 0.35 | body − 0.15 |
| Glans | ellips center (-0.175r, -0.31r), halve assen 0.375r × 0.21r, alpha 0.45 | wit |
| Oog wit | cirkel (0.55r, -0.22r), straal 0.30r, outline 3 px | wit |
| Iris | zelfde center, 0.18r | `skin.eye` |
| Pupil | zelfde center, 0.105r | zwart |
| Oog-glans | (0.43r, -0.34r), straal 0.045r | wit |

- **Lichaamskleur:** `ratio = inflate_level / 14`; ≥0.8 → body − 0.2 (per RGB-kanaal, min 0); ≥0.5 → body − 0.1; anders body.
- **Stekels:** alleen als `inflate_level > 3`. Aantal = `min(10, int(inflate_level * 1.1))`, gelijk verdeeld over 360°. Positie `(cos a · 1.08r, sin a · 0.92r)`. Straal `clamp(inflate_level * 0.22, 1.2, 3.5)`, zwarte rand +2 px. Kleur `skin.spine`.
- **Knipperen:** elke 180 ticks, 6 ticks dicht → oog wordt zwarte balk `2·eyeR × 4 px`, iris/pupil/glans verborgen.
- **Staartzwiep:** `wag += 0.15 * dir`, keer om bij |wag| > 2; offset `w = round(wag) * 2` (geeft het pixelige stapje).

## Acceptatiecriteria
- [ ] Getekend in `_draw()`, `queue_redraw()` per tick. Geen child-nodes per stekel.
- [ ] Skin wordt uit `SaveManager.selected_skin` gelezen (data in US-18).
- [ ] `darken(color, amount)` helper in een util-script (hergebruikt door menu/splash).
- [ ] Herbruikbare "statische vis"-tekenfunctie `draw_menu_fish(canvas, skin, r, spine_count)` voor menu (r=52, 8 stekels), splash (r=62, 10 stekels) en skin-kaartjes (r=22, 6 stekels). Deze varianten hebben een zwarte outline van +3 px rondom (offset-ellips) i.p.v. stroke.
- [ ] Visueel naast de Swift-versie gelegd bij inflate 0, 7 en 14.
