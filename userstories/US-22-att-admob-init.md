# US-22 — Tracking-toestemming (ATT) en AdMob-initialisatie
**Epic:** Monetisatie · **Prio:** Must · **Omvang:** M

**Als** studio-eigenaar **wil ik** dat de app netjes om tracking-toestemming vraagt en daarna AdMob start, **zodat** ik advertentie-inkomsten heb en aan de App Store-regels voldoe.

## Context (Swift — `AppDelegate.swift`, `Info.plist`)
- AdMob App ID: `ca-app-pub-3366446717708247~5105910064` (`GADApplicationIdentifier`).
- `NSUserTrackingUsageDescription`: "We use this to show you relevant ads and improve your experience."
- 2 s na launch → als ATT-status `notDetermined`: na nog 1 s de ATT-prompt; na antwoord (of als al eerder beantwoord) → `MobileAds.start()`. Eén keer per sessie.
- Debug: test-device IDs `SIMULATOR` en `5538de831287f2fd84dfa736cfdea1d5`.
- SDK: Google Mobile Ads 13.3.0 + User Messaging Platform 3.1.0 (zit in Package.resolved, maar UMP/consent wordt **niet** gebruikt in de code).

## Acceptatiecriteria
- [ ] Godot iOS-plugin voor AdMob geïnstalleerd (bv. Poing Studios *godot-admob-plugin*; controleer compatibiliteit met Godot 4.7 vóór start) + ATT-ondersteuning (plugin of eigen kleine iOS-plugin).
- [ ] App ID en tracking-tekst in de iOS-exportpreset (`Info.plist` additions).
- [ ] Zelfde volgorde: ATT eerst, AdMob pas daarna initialiseren. Prompt verschijnt pas na de studio-splash (≈3 s), niet bovenop het launchscreen.
- [ ] Test-ad-units in debug-builds, productie in release (bevinding B8).
- [ ] **EU/AVG:** UMP-consentformulier tonen vóór ATT voor gebruikers in de EER. Dit ontbreekt in het origineel; Google eist het voor gepersonaliseerde ads in de EER/UK. Advies: meenemen in deze rebuild.
- [ ] App blijft volledig speelbaar als ATT geweigerd wordt of AdMob niet laadt (offline).
- [ ] Privacy-manifest (`PrivacyInfo.xcprivacy`) en App Store "App Privacy"-gegevens kloppen met AdMob-gebruik.
