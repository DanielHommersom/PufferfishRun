# US-17 — Hoofdmenu
**Epic:** Schermen · **Prio:** Must · **Omvang:** M

**Als** speler **wil ik** een menu met mijn beste score, uitleg van de besturing en knoppen om te spelen of een skin te kiezen, **zodat** ik snel kan beginnen.

## Context (Swift — `MenuScene.swift`). Posities in Godot (vanaf boven), `h` = schermhoogte.
**Achtergrond:** banden zone 0 (boven 0–55%, midden 55–82%, onder 82–100%), 3 koraalstompen op x = 60, w/2, w−60 met hoogte 80/60/80 (US-16), 6 bubbels.

| Element | Positie | Details |
|---|---|---|
| Vis (gekozen skin) | (50%, 38%) | r = 52, 8 stekels; dobbert 14 px op/neer, 0.9 s per richting, ease-in-out |
| BEST: {n} | y = 0.56h − 50 | 13 pt, `UI_GOLD_TEXT` |
| PUFFERFISH | y = 56% | 38 pt wit; fade-in 0.5 s + 20 px omhoog (ease-out); schaduw |
| RUN | y = 63% | 52 pt `UI_ORANGE`; na 0.2 s fade-in + y-schaal 0.7 → 1.0 in 0.4 s; schaduw |
| Tutorial-paneel | 280×72, onderkant op 73% | bg `PANEL_BG`, 3 px zwarte rand, radius 12; pulseert schaal 1.0 ↔ 1.03 (0.9 s) |
| — links | | "▲" + "HOLD" (11 pt) op 25% van paneelbreedte |
| — scheiding | | 2 px lijn `(0.2,0.4,0.6)` in het midden |
| — rechts | | "▼" + "RELEASE" op 75% |
| TAP TO PLAY | 300×68, onderkant op 82% | `UI_ORANGE`, zwarte tekst 18 pt |
| SELECT SKIN | 220×52, onderkant op 90% | `UI_BLUE`, witte tekst 13 pt |
| Mute-knop | (w−50, h−50) | US-21 |

**Knopstijl** (ook GameOver): zwarte schaduw +4/+4 radius 14, knop met 3 px zwarte rand radius 12, witte glans 20% over de bovenste ~35%, pulseert schaal 1.0 ↔ 1.04 (0.7 s).

## Acceptatiecriteria
- [ ] Herbruikbare `PixelButton` scene (`Button` met `StyleBoxFlat` of eigen `_draw`) met `text`, `color`, `text_color`, `size`, `pulse`; schaalt vanuit het midden (`pivot_offset`).
- [ ] TAP TO PLAY → fade 0.3 s naar Game. SELECT SKIN → moveIn-up naar SkinSelect.
- [ ] Alleen tikken **op** een knop doet iets (origineel: geen tap-anywhere, ondanks de tekst "TAP TO PLAY").
- [ ] Best-score en vis-skin worden bij elk bezoek opnieuw uit `SaveManager` gelezen.
- [ ] Layout overlapt niet op 375×667 (iPhone SE) — controleer met name tutorial-paneel vs. knoppen.

## Notities
- Swift-pulse schaalt vanuit de linkeronderhoek van de shape (geen anchor) en de tekst pulseert niet mee. In Godot vanuit het midden en tekst mee — bewuste verbetering.
