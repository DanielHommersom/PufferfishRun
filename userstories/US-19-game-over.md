# US-19 — Game-over scherm met medailles
**Epic:** Schermen · **Prio:** Must · **Omvang:** M

**Als** speler **wil ik** na mijn dood mijn score, beste score en een eventuele medaille zien, **zodat** ik weet hoe goed ik het deed en gemotiveerd ben opnieuw te spelen.

## Context (Swift — `GameOverScene.swift`). Posities in Godot (vanaf boven).
- Achtergrond `(0.02,0.08,0.16)` + 55% zwarte overlay, 5 bubbels (US-13), mute-knop (US-21).
- Bij openen: `AdManager.on_player_died()` (US-23) en highscore opslaan.
- **Titel** "GAME OVER" 36 pt `(1.0,0.267,0.267)` op y = 20%, met schaduw; start schaal 2.0 / alpha 0 → fade-in 0.3 s + schaal naar 1.0 in 0.4 s.
- **Scorepaneel** 300×220, onderkant op 54%: glow-rand 4 px `(0.102,0.416,0.478)` radius 22, paneel `PANEL_BG` radius 20 met zwarte rand.
  - "SCORE" 13 pt `UI_MUTED_TEXT`; waarde 52 pt wit, **telt op** van 0 naar score: elke 0.04 s `+ max(1, score / 20)` (≈ 0.8 s totaal).
  - Scheidingslijn 2 px `UI_BLUE`.
  - "BEST" 13 pt; waarde 42 pt — `UI_ORANGE` bij nieuw record, anders wit.
  - "NEW BEST!" 11 pt `UI_ORANGE`, pulseert schaal 1.0 ↔ 1.15 (0.3 s) — alleen bij nieuw record.
  - **Medaille** links in het paneel (cirkel r24, zwarte rand, label 9 pt zwart):
    | Score | Medaille | Kleur |
    |---|---|---|
    | ≥ 40 | GOLD | (0.969,0.761,0.204) |
    | ≥ 20 | SILVER | (0.753,0.753,0.753) |
    | ≥ 10 | BRONZE | (0.804,0.498,0.196) |
- **Knoppen** 280×62 (stijl US-17), tekst 16 pt wit:
  - PLAY AGAIN `UI_GREEN`, onderkant op 66%; verschijnt na 0.9 s (fade-in + 30 px omhoog, 0.4 s ease-out).
  - MAIN MENU `UI_BLUE`, onderkant op 76%; verschijnt na 1.1 s.
  - Beide fade 0.3 s naar Game resp. Menu.

## Acceptatiecriteria
- [ ] Alles zoals hierboven.
- [ ] **Bugfix B2:** "NEW BEST!" en oranje best-waarde alleen als `score > vorige best` **en** `score > 0` (gebruik retourwaarde van `SaveManager.submit_score`).
- [ ] Knoppen zijn niet klikbaar voordat ze zichtbaar zijn (voorkomt per ongeluk direct opnieuw starten door een doorlopende tik).
- [ ] Na tellen staat exact de eindscore er (geen overshoot).
- [ ] Een nieuw ontgrendelde skin wordt **niet** gemeld in het origineel — kandidaat voor een aparte verbeterstory.
