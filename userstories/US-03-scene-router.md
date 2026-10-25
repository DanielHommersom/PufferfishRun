# US-03 — Schermovergangen (SceneRouter)
**Epic:** Fundament · **Prio:** Must · **Omvang:** S

**Als** speler **wil ik** vloeiende overgangen tussen schermen, **zodat** de game net zo gepolijst aanvoelt als het origineel.

## Context (Swift)
Overgangen via `SKTransition`:
| Van → naar | Overgang | Duur |
|---|---|---|
| StudioSplash → Splash | fade | 0.3 s (na 0.5 s logo fade-out) |
| Splash → Menu | fade | 0.6 s (auto) / 0.4 s (tap) |
| Menu → Game | fade | 0.3 s |
| Menu → SkinSelect | moveIn van **onder naar boven** | 0.3 s |
| SkinSelect → Menu | moveIn van **boven naar beneden** | 0.3 s |
| Game → GameOver | fade | 0.3 s (na 0.8 s death-delay) |
| GameOver → Game / Menu | fade | 0.3 s |

## Acceptatiecriteria
- [ ] Autoload `SceneRouter` met `go_to(scene: PackedScene / path, transition: Transition, duration: float, params := {})`.
- [ ] Transities: `FADE` (zwarte `ColorRect` op `CanvasLayer` layer 100, in- en uitfaden), `MOVE_IN_UP`, `MOVE_IN_DOWN` (nieuwe scene schuift over de oude).
- [ ] Parameters doorgeven (GameOver heeft `score` nodig).
- [ ] Input wordt geblokkeerd tijdens een transitie (geen dubbele taps → dubbele scenes).
- [ ] Main scene van het project = StudioSplash.

## Notities
- Bij moveIn blijft de oude scene zichtbaar tot de nieuwe eroverheen ligt; implementeer door beide tijdelijk onder een container te hangen of via een screenshot-texture van de oude scene.
