# US-15 — Studio-splash Digital Diamonds
**Epic:** Schermen · **Prio:** Must · **Omvang:** S

**Als** studio-eigenaar **wil ik** bij het opstarten het Digital Diamonds-logo tonen, **zodat** de game herkenbaar onder mijn merk valt.

## Context (Swift — `StudioSplashScene.swift`)
- Achtergrond `(0.06, 0.04, 0.10)`.
- Logo = inline SVG (diamant uit 9 polygonen met paars→blauw→cyaan gradients + tekst "DIGITAL" / "DIAMONDS", Arial Black 52, viewBox `55 0 584 280`) in een `WKWebView`, 90% schermbreedte, max 500 px, verticaal gecentreerd.
- Timing: na 0.4 s fade-in 0.6 s (ease-out) → staat tot 2.8 s → fade-out 0.5 s → fade 0.3 s naar Splash.
- Tik = direct doorgaan (fade-out + overgang).

## Acceptatiecriteria
- [ ] SVG uit `StudioSplashScene.swift` exporteren naar PNG @3x (± 1500 px breed) in `assets/images/dd_logo.png`. **Niet** de SVG direct importeren: Godot's SVG-import (ThorVG) rendert `<text>` niet betrouwbaar en dan valt de woordmerk-tekst weg.
- [ ] `TextureRect` gecentreerd, breedte `min(0.9 * w, 500)`, aspect behouden.
- [ ] Tijdlijn en tap-to-skip zoals hierboven; tap tijdens de fade-in skipt ook.
- [ ] Dit is de main scene van het project.

## Notities
- Overweeg een iOS launch-screen in dezelfde achtergrondkleur zodat er geen witte/zwarte flits is vóór deze scene (zie US-24).
