# US-12 — Vijand: zee-egel
**Epic:** Gameplay · **Prio:** Must · **Omvang:** S

**Als** speler **wil ik** vanaf score 25 een zee-egel die diagonaal stuitert, **zodat** ik ook verticale dreiging moet inschatten.

## Gedrag
- Straal (hitbox) **18** (stekels reiken visueel tot 30, tellen niet mee).
- Spawn x = `screen_w + 30`, y = random 60 … `screen_h - 60`; verticale snelheid random ±1.6.
- Per tick: `x -= 2.2`; `y += vel_y`; als `y < 30` of `y > screen_h - 30` → `vel_y *= -1`.

## Uiterlijk
- Lichaam: zwart r21, `(0.173, 0.243, 0.314)` r18.
- Glans: wit alpha 0.4, r6 op (-5, -5).
- Oog in het midden: zwart r7, `(0.910, 0.298, 0.235)` r5, pupil r2.5 op (1, -1).
- **12 stekels** (geanimeerd): hoek `i/12 * TAU`, van binnenstraal 18 naar buitenstraal 30; tip krijgt wobble `sin(time*3 + i) * 2` op x én y. Zwarte driehoek basisbreedte 4, vulling `(0.933, 0.933, 0.933)` basisbreedte 2.

## Acceptatiecriteria
- [ ] Stuitert tegen boven/onderrand en blijft in beeld.
- [ ] Stekels wiebelen zichtbaar.

## Notities
- Origineel: de stekelbasis wordt horizontaal verschoven (`ix ± 2`) ongeacht de hoek, waardoor verticale stekels dunner ogen. Optioneel corrigeren door loodrecht op de hoek te verschuiven.
