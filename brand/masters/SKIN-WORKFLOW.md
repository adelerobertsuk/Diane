# Machine skins workflow (locked 20 Aug 2026)

Kate-approved. Do not invent a new layout path.

## What ships

Each machine is one **phone wallpaper PNG**:
- Size: **1206 × 2622** (iPhone screenshot / wallpaper size Kate used)
- Wash: warm studio `#F3EDE4` (or matching pearlescent wash) full bleed in the file
- Machine already placed with air under Dynamic Island and side margins
- Cassette baked into the art for now
- No app icons in the PNG

## Cursor install (same every time)

1. Adele drops art in chat or Downloads. Cursor takes it. Do not ask her where to save.
2. Archive to `brand/masters/{Name}-idle.png` (+ rec twin if separate) and `brand/masters/approved/`.
3. Copy into Assets:
   - Diane → `SkinCooper*`
   - Cooper → `SkinNoir*`
   - Palmer → `SkinSteel*`
   - Earle → `SkinEarle*`
4. Measure Record / Volume / cassette window hits → `{Name}-hits.json` + `Models.swift`.
5. App layout: **aspect-fit** wallpaper on studio wash. Chrome auto-hides (MyTablo-style).
6. Build on **iPhone 17 Pro** Simulator. Screenshot to `brand/ui-shots/{Name}-sim-kate-fit.png`.
7. Done when it matches Kate’s phone-fit reference. No more inset experiments.

## Do not

- Aspect-fill crop of wrong-aspect art
- Floating “card” layouts that fight the wallpaper
- Cassette video under opaque stills
- GG token chases for tiny ChatGPT proofs. Use full wallpaper files only.
