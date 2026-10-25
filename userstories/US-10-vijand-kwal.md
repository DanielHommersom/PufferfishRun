# US-10 — Vijand: kwal
**Epic:** Gameplay · **Prio:** Must · **Omvang:** S

**Als** speler **wil ik** een langzame, golvende kwal tegenkomen vanaf score 5, **zodat** ik moet timen wanneer ik erlangs ga.

## Gedrag
- Straal (hitbox) **22**. Spawn x = `screen_w + 40`, y = random 80 … `screen_h - 80`.
- Per tick: `x -= 1.4`; `y = base_y + sin(time * 1.8) * 55`.

## Uiterlijk (Godot-coördinaten, y gespiegeld)
- Klok: zwarte ellips center (0, -18), halve assen 24×18; daarin paarse ellips center (0, -17), 20×15, kleur `(0.608, 0.349, 0.714)`.
- Glans: witte ellips alpha 0.5, center (-2, -22.5), 8×4.5.
- 3 stippen straal 3 op (-8,-14), (0,-16), (8,-14), kleur `(0.490, 0.235, 0.596)`.
- Oog op (0, -10): zwart r7, wit r5, pupil r3 op (1, -9).
- **Tentakels** (geanimeerd): 6 strengen op x = `i*8 - 20`, elk 4 segmenten van 3×7 px, segment j op y = `j*8` (naar beneden), x-offset `sin(time*2 + i*0.8 + j*0.4) * 4`. Kleur `(0.490, 0.235, 0.596)`.

## Acceptatiecriteria
- [ ] Beweging en vorm zoals hierboven; tentakels wiegen zichtbaar.
- [ ] Botst met straal 22 (−4 marge uit US-08).
