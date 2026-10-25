# US-04 — Kogelvis besturen (opblazen en zakken)
**Epic:** Gameplay · **Prio:** Must · **Omvang:** M

**Als** speler **wil ik** door het scherm ingedrukt te houden de vis op te blazen en te laten stijgen, en door los te laten te laten zakken, **zodat** ik door de openingen kan navigeren.

## Context (Swift — `PufferFish.updatePhysics`, `GameScene.touchesBegan/Ended`)
Per frame:
```
if inflating:
    inflate_level = min(14, inflate_level + 0.35)
    vel_up += 0.42            # INFLATE_SPEED * 1.2
else:
    inflate_level = max(0, inflate_level - 0.18)
    vel_up -= 0.22            # GRAVITY
vel_up = clamp(vel_up, -5, 5)
position.y -= vel_up          # Godot: y omlaag, dus aftrekken
radius = 18 + inflate_level * 0.85    # 18 … 29.9 px
```

## Acceptatiecriteria
- [ ] `PufferFish` (`Node2D`) met `inflate()`, `deflate()`, `get_radius()`, `vel_up`, `inflate_level`.
- [ ] Startpositie: x = 25% schermbreedte, y = 50% schermhoogte; start met `vel_up = 0`, `inflate_level = 0`.
- [ ] Physics in `_physics_process` exact zoals hierboven (per tick, zie conventie 2).
- [ ] Input: `InputEventScreenTouch` pressed → `inflate()`, released → `deflate()`. Ook muis-links voor testen op desktop.
- [ ] Multi-touch: vis blijft opgeblazen zolang **minstens één** vinger het scherm raakt (Swift negeert dit en deflate bij de eerste vinger die loslaat — kies bewust; advies: tel actieve touches).
- [ ] Tik op de mute-knop (US-21) mag de vis **niet** laten opblazen.
- [ ] Na game over: input genegeerd, vis gedeflate.
- [ ] Opblaasgeluid alleen bij het begin van een druk, niet herhaald tijdens vasthouden (zie US-20).

## Testscenario's
- Niets doen vanaf start → vis valt en raakt na ~1,5 s (≈93 ticks) de onderkant (bij 852 hoog).
- Constant vasthouden → vis bereikt max snelheid 5 px/tick (300 px/s) omhoog.
