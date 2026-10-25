# US-11 — Vijand: haai
**Epic:** Gameplay · **Prio:** Must · **Omvang:** S

**Als** speler **wil ik** vanaf score 15 een snelle haai tegenkomen, **zodat** ik snel moet reageren.

## Gedrag
- Straal (hitbox) **32**. Spawn x = `screen_w + 60`, y = random 60 … `screen_h - 60`.
- Per tick: `x -= 4.0` (sneller dan de zuilen op max); `y = base_y + sin(time * 0.6) * 20`.

## Uiterlijk (Godot-coördinaten, y gespiegeld). Haai kijkt naar **links** (bek links, staart rechts).
- Lichaam: zwarte ellips 36×18 (halve assen) op (0,0); daarin `(0.365, 0.541, 0.659)` 33×16.
- Buik: ellips center (3, 4), halve assen 19×8, `(0.839, 0.918, 0.973)`.
- Rugvin: zwart driehoek (-4,-16),(14,-16),(8,0); vulling (-2,-14),(12,-14),(7,0) in lichaamskleur.
- Staart (rechts): twee driehoeken zwart (30,18),(42,18),(30,0) en (30,0),(42,-18),(30,-18); vulling iets kleiner in `(0.29, 0.48, 0.59)`.
- Oog op (-18, -4): zwart r8, wit r6, pupil r3 op (-17, -3).
- 3 tanden: witte driehoekjes met 1 px zwarte rand, op x = `30 + i*7`, (tx,4),(tx+6,4),(tx+3,10).

## Acceptatiecriteria
- [ ] Beweging en vorm zoals hierboven.
- [ ] Hitbox is een cirkel r32 hoewel het lichaam 72 breed is — pariteit met origineel.

## Notities
- **Bug in origineel:** tanden staan op x = 30…44, dat is bij de **staart**, niet bij de bek (`CGFloat(i) * 7 - -30`, waarschijnlijk bedoeld als `- 30`). Advies: in Godot naar de bek verplaatsen (x = `-30 + i*7`). Beslis en noteer.
