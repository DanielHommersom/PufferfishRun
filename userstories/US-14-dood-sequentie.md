# US-14 — Dood-animatie en overgang naar game over
**Epic:** Gameplay · **Prio:** Must · **Omvang:** S

**Als** speler **wil ik** een korte, duidelijke dood-animatie, **zodat** ik snap wat er gebeurde voordat het game-over-scherm komt.

## Context (Swift — `GameScene.triggerGameOver`)
Volgorde bij de eerste hit:
1. `game_over = true` (guard: slechts één keer).
2. Game-over-geluid (US-20).
3. Vis deflate; alle vijanden direct weg.
4. Vis schaalt naar 0 **en** fadet uit in 0.4 s (parallel).
5. 8 bubbels op de vispositie: straal 4–10, kleur `(0.533, 0.867, 1.0)` alpha 0.7, geen rand. Elk bewegen ze `dx` random −50…50 en **omhoog** 20…80 px in 0.6 s terwijl ze uitfaden; daarna verwijderen.
6. Na **0.8 s** → `SceneRouter` fade (0.3 s) naar GameOver met `score`.

## Acceptatiecriteria
- [ ] Zuilen blijven stilstaan op hun plek tijdens de animatie (update-loop stopt).
- [ ] Geen input of score meer na stap 1.
- [ ] Score wordt als parameter aan GameOver doorgegeven; highscore opslaan gebeurt in GameOver/SaveManager (US-19), niet hier.
