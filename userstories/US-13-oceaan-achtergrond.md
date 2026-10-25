# US-13 — Oceaan-achtergrond en diepte-zones
**Epic:** Gameplay · **Prio:** Must · **Omvang:** M

**Als** speler **wil ik** dat de zee donkerder wordt naarmate ik verder kom, **zodat** ik voel dat ik dieper de oceaan in zwem.

## Context (Swift — `OceanBackground.swift`)
**Drie horizontale banden** (Godot, vanaf boven):
| Band | y van – tot |
|---|---|
| Boven | 0 – 55% |
| Midden | 55% – 82% |
| Onder | 82% – 100% |

**Zones** (wisselen op score):
| Zone | Vanaf score | Boven | Midden | Onder | Lichtstraal-alpha |
|---|---|---|---|---|---|
| 0 Shallow reef | 0 | `(0.306,0.753,0.792)` | `(0.165,0.541,0.604)` | `(0.051,0.227,0.361)` | 0.18 |
| 1 Open water | 10 | `(0.102,0.416,0.541)` | `(0.051,0.290,0.416)` | `(0.024,0.125,0.251)` | 0.10 |
| 2 Deep ocean | 25 | `(0.039,0.165,0.290)` | `(0.024,0.094,0.157)` | `(0.008,0.039,0.078)` | 0.04 |

- Zonewissel = kleuren én straal-alpha tweenen in **2.0 s**. Bij start direct zone 0 zonder animatie.
- **4 lichtstralen** op x = 15%, 38%, 62%, 82%: trapezium van 10 px breed aan de bovenrand naar 50 px breed op y = 60% schermhoogte. Kleur `(0.365, 0.831, 0.867)`.
- **8 bubbels:** straal 6–16, wit alpha 0.15, 2 px zwarte rand, random x (20 … w-20), random start-y. Stijgen over de volle hoogte + 40 in 4–8 s (random per bubbel), daarna reset onder het scherm op nieuwe random x; oneindig.
- Achtergrond op z-index −10, scrollt **niet** mee.

## Acceptatiecriteria
- [ ] Scene `OceanBackground` met `update_score(score)`; alleen tweenen als de zone echt verandert.
- [ ] Banden als `ColorRect`s of `_draw()`; tween op `color`.
- [ ] Bubbels als herbruikbaar component `BubbleField(count, radius_range, alpha, random_start_delay)` — wordt ook gebruikt in menu (6×, 5–14, 0.12), splash (7×, 6–16, 0.12, start-delay 0–3 s) en game over (5×, 5–12, 0.10, start-delay 0–3 s, starten onder beeld).
- [ ] Geen zichtbare sprong in kleur bij zonewissel.
