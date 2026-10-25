# US-16 — Game-splash met titel
**Epic:** Schermen · **Prio:** Must · **Omvang:** M

**Als** speler **wil ik** een geanimeerd titelscherm, **zodat** de game sfeer neerzet voordat het menu verschijnt.

## Context (Swift — `SplashScene.swift`). Posities in Godot (vanaf boven).
**Achtergrond:** banden boven 0–45%, midden 45–82%, onder 82–100% (kleuren zone 0, US-13). 4 lichtstralen op 20/45/65/82% breedte, 12 px boven → 80 px breed op 65% hoogte, alpha 0.14. 4 koraalstompen vanaf de onderrand op x 12/28/72/88% met hoogtes 90/65/70/95 (zwart 30 breed, vulling `CORAL_BASE` 24 breed, hoekradius 4/3). 7 bubbels (US-13).

**Vis:** standaard-skin, r = 62, 10 stekels, op (50%, 40%). Start alpha 0 / schaal 0.4; na 0.3 s fade-in 0.5 s + schaal naar 1.0 in 0.6 s (ease-out). Vanaf 0.9 s eeuwig dobberen: 16 px op en neer, 1.1 s per richting.

**Tekst** (monospace bold, met schaduw 40% zwart op +4/+4 px):
| Tekst | Pos y | Grootte | Kleur | Animatie |
|---|---|---|---|---|
| PUFFERFISH | 68% | 42 | wit | na 0.7 s fade-in 0.5 s + 20 px omhoog |
| RUN | 77% | 60 | `UI_ORANGE` | na 0.9 s fade-in 0.4 s + schaal 0.6 → 1.0 |
| SURVIVE THE REEF | 84% | 16 | wit 70% | na 1.1 s fade-in + 20 px omhoog |
| ... | 92% | 14 | wit 40% | na 1.4 s fade-in 0.3 s, daarna pulseren alpha 0.2 ↔ 0.6 (0.5 s) |

**Doorgaan:** na 3.2 s fade 0.6 s naar Menu; tik = direct fade 0.4 s.

## Acceptatiecriteria
- [ ] Alle elementen en timings zoals hierboven, gebouwd met `Tween`.
- [ ] Vis via de gedeelde tekenfunctie uit US-05.
- [ ] Koraalstomp als herbruikbare `CoralStump(height)` (ook in menu).
