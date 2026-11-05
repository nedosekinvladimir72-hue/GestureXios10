# GestureX v0.2 — source prototype

Target: iPhone 5 / ARMv7 / iOS 10.3.4 / H3lix / Cydia Substrate.

## Implemented in source
- Animated custom Home Indicator (fade + spring scale).
- Pixel-aligned indicator geometry for @2x display.
- Edge gesture recognizers for bottom, top-right and top-left zones.
- Candidate SpringBoard selector calls for Home, App Switcher, Control Center and Notification Center.

## Not implemented / not verified
- Native iPhone X app-switcher card transition and interactive card physics.
- True app-to-app swipe switching.
- Verified iOS 10.3.4 private SpringBoard selectors.
- Relocation of the actual system Control Center UI. The prototype only attempts to invoke candidate presentation selectors.
- Device performance, touch pass-through and stability on hardware.

This is deliberately marked experimental. Do not install on your primary device until compiled and tested with a recovery path available. The transparent overlay and private SpringBoard calls may need device-specific changes.

## Build
Requires Theos configured with an iOS 10.3 SDK and an ARMv7 toolchain:
`make package`

The package is rootful (H3lix), not rootless. This source project has not been compiled here.
