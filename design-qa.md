# Reference HUD and controls QA

Scope: the supplied HUD and touch controls inside the existing Godot game. The
world art, lighting, camera framing and enemy population are outside this change.

- Source visual truth: `tests/references/hud-target.jpg` (1280 × 590 pixels).
- Browser-rendered implementation: `build/logs/hud-browser-1280x590.png`.
- Matching viewport: 1280 × 590 CSS pixels, device scale factor 1; no density scaling.
- Responsive browser capture: `build/logs/hud-browser-844x390.png`, 844 × 390, DPR 1.
- State: reference fixture with health 100/100, 3 of 5 Fury segments, level 7,
  1/3 ARSENAL, 1005 credits, machine gun 18/24. Production values remain live.
- Full-view combined comparison: `build/logs/hud-browser-comparison-final.png`.
- Focused top-bar comparison: `build/logs/hud-top-comparison-final.png`.
- Interaction evidence: `build/logs/hud-browser-1280.json` and
  `build/logs/hud-browser-844.json`; both report no page errors or Godot errors.

## Comparison history

1. Initial native comparison (`build/logs/hud-comparison-v1.png`) found P2:
   oversized metal rims compressed the panel interiors, Fury caption was too
   small, and a floating distance label was outside the selected HUD design.
2. Fixed panel nine-slice scale, Fury caption size/color/offset, mission typography,
   crate/gun sizing, and removed the floating label. Captured the result in the
   actual WebGL export at the matching viewport and reference state.
3. Final browser comparisons listed above show no remaining actionable P0/P1/P2
   differences within the requested HUD/control scope.

## Fidelity surfaces

- Typography: white heavy display counters and objective title, compact Fury
  caption, readable health fractions and ammo capacities. No wrapping or truncation.
- Layout: portrait/health/Fury grouped at upper left; objective centered above;
  credits/ammo/gear across the upper right; move disk at lower left; aim disk,
  gold jump circle and smaller swap circle at lower right. Positions are normalized
  from the source and remain inside the mobile viewport.
- Colors/tokens: navy panels, silver rims, red health/heart, cyan Fury/gun, gold
  coins/badge/jump outline. Segment fill is derived from live XP or ability duration.
- Assets: generated transparent raster atlas matches the source's cartoon portrait,
  beveled icons and chrome controls. No placeholders, baked counters or replacement
  glyph icons. Region metadata slices the atlas directly in Godot.
- Copy/content: matching labels and sample values in the QA fixture; live values
  and the run's Fury level in production.

## Primary interactions tested

- Simultaneous movement and aim/fire with independent touch IDs.
- Third-finger weapon toggle in both directions without stealing the two sticks.
- Third-finger jump while moving/aiming.
- Gear opens pause/settings; gear closes it; Escape and keyboard weapon shortcuts
  remain supported by the native regression suite.
- Browser captures and interactions at both 1280 × 590 and 844 × 390.
- Browser console and page errors checked: none.

## Follow-up polish (P3 only)

The raster recreation has minor portrait shading and joystick stroke differences
from the illustration. World/background differences are expected and outside scope.
Physical-device input latency and display-density checks remain manual follow-up.

## Implementation checklist

- [x] All artwork assets wired into the running game.
- [x] HUD/reference comparison at matching dimensions and state.
- [x] Focused top-bar and full-view comparisons inspected.
- [x] Touch ownership, swap, jump, settings and responsive bounds verified.
- [x] Native gameplay regression suite and export passed.

final result: passed
