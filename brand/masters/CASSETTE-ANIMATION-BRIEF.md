# Diane cassette animation — Cursor asset brief for GG

**Date:** 20 Aug 2026  
**Platform:** Native iOS (SwiftUI + UIKit). Not web/CSS.  
**Design lock:** No illustrated Action Button on machines. Hardware Action Button / Watch = app/device only.  
**Status:** Build Diane cassette system first. Same architecture later for Cooper, Palmer, Earle.

**Current code (today):** Full-bleed skin PNG + `AVPlayerLayer` video under `cassetteWindow` alpha hole (`TapeStage.swift` / `CassetteLoop.swift`). We will replace video with layered Swift animation once these assets land. Window spots in code today are for the **old landscape** Diane; new Prada-silhouette Diane will replace them when the master is measured.

---

## Answers for GG (1–15)

### 1. Exact pixel dimensions / aspect for the Diane cassette animation plate

**Plate canvas = the cassette aperture, not the whole phone.**

| Spec | Value |
| --- | --- |
| Working plate (until master is measured) | **720 × 1080** px (portrait, 2:3) |
| Colour | sRGB |
| Format | PNG-24 + alpha (RGBA) |
| After Diane master locks | Resize plate to **exact window pixel box** on the 1410×3072 master (or 2× that box if window &lt; 360 px on the short side). All layers share one plate size. |

Do **not** put the full dictaphone on this plate. Only what lives inside the window.

### 2. Visible window / aperture (position + size)

**On the machine master (1410 × 3072):**

- Cassette window must be a **true alpha hole** (alpha = 0), hard edge or 1 px anti-alias max.
- GG returns a `SkinSpot` in **normalised 0–1** of the full master:

```text
cassetteWindow: { x, y, w, h }
```

Example format (replace with real numbers from the approved Diane master):

```text
cassetteWindow: x=0.18 y=0.16 w=0.42 h=0.28
```

Cursor maps that through the same `SkinFill` aspect-fill math used today.

**On the animation plate:** the plate **is** the aperture. Content should fill the plate; leave **8–12 px** transparent margin inside the plate edge so reels never clip against the bezel when rotating.

### 3. Preferred PNG dimensions for each reel

| Asset | Size |
| --- | --- |
| `reel-left.png` | **512 × 512** RGBA |
| `reel-right.png` | **512 × 512** RGBA |

Square. Same size both. Drawn larger than on-screen; Cursor scales down into the plate. Hub / teeth must read at ~120–180 pt on device.

### 4. Reel pivots

**Image centre = pivot.** No offset coordinates required if artwork is centred.

If a reel’s visual hub is not geometrically centred, either:

- re-centre the art, or  
- supply `pivotNormalized: { x: 0.5, y: 0.5 }` overrides in the layout JSON (see §15).

Default assumption: **0.5, 0.5**.

### 5. Transparent padding around reel artwork

- Reel artwork diameter ≈ **78–82%** of the 512 box (leaves ~9–11% padding each side).
- Outside the reel disc: **alpha 0**.
- No drop shadow baked into the reel file (shadows live in well/shell if needed).
- Soft 1 px edge AA OK; no white matte / halo.

### 6. Preferred z-order (bottom → top)

1. `well.png` — dark interior, walls, felt, rollers, shadows  
2. `reel-left.png` — rotating  
3. `reel-right.png` — rotating  
4. `tape.png` — optional ribbon / pack between reels (static or very subtle)  
5. `shell.png` — cassette body / label / hubs ring with **transparent holes** over the reels  
6. `glass.png` — optional smoked glass, dust, specular (mostly transparent)

Machine master skin sits **above** this whole stack and masks everything to the aperture.

### 7. Masking requirements

- Machine master: rectangular (or intentional) **alpha hole** = only mask required at skin level.  
- `shell.png`: two circular (or hub-shaped) **alpha holes** aligned to reel centres so spinning reels show through.  
- Cursor will also `clipsToBounds` on the window view. Do not rely on soft vignette as the only mask.  
- No baked black rectangle where transparency is required.

### 8. Glass / reflections: master or overlay?

**Prefer separate `glass.png` overlay** (layer 6).

- Keeps idle/rec masters cleaner.  
- Lets Cursor dim glass slightly while rolling if useful.  
- Heavy bezel chrome stays in the **machine master**; only window glass/scuffs on `glass.png`.

### 9. Cassette shell vs independent reels

**Yes: one static `shell.png` + independent reels underneath (showing through holes).**

- Shell does **not** rotate.  
- Reels are not part of the shell pixels.  
- Label / “Diane 60” text lives on `shell.png` (or a `label.png` if you need to swap later).

### 10. File naming convention

Drop in `Studio/Diane/brand/masters/cassette/Diane/` (create if needed):

```text
Diane-cassette-well.png
Diane-cassette-shell.png
Diane-cassette-reel-left.png
Diane-cassette-reel-right.png
Diane-cassette-tape.png          (optional)
Diane-cassette-glass.png         (optional)
Diane-cassette-layout.json       (required)
```

Machine faces (separate):

```text
Diane-idle.png
Diane-rec.png
```

### 11. Resolution / @2x / @3x

App assets today are **single universal PNGs** in `.xcassets` (no @2x/@3x slots).

- Deliver **one high-res file** per layer at the sizes above.  
- Cursor installs as universal.  
- Do **not** upscale small proofs. Native pixels only.

### 12. Performance constraints

- Keep the stack to **≤ 6 layers**.  
- Prefer opaque-ish well + shell; avoid huge full-screen blur plates.  
- Reel PNGs 512² is enough; do not ship 2k×2k reels.  
- Animation = `CADisplayLink` / SwiftUI rotation of two images at ~30–60 fps equivalent; no video decode once layers ship.  
- No animated GIF/APNG.  
- Total cassette pack target: **&lt; ~8 MB** uncompressed PNG; compress sensibly without banding on cream/gold.

### 13. Idle vs record artwork

| Element | How |
| --- | --- |
| Machine body | Prefer **Diane-idle.png** + **Diane-rec.png** (identical geometry; jewel lit on rec) **or** single idle + Cursor glows the jewel via hit spot. Painted jewel pair is richer. |
| Cassette layers | **One set only.** Cursor starts/stops rotation. Do not duplicate reel art for rec. |
| Rec LED | If painted in master pair → no code lamp. If single master → supply `recLamp` spot; Cursor composites glow. |

**Recommendation:** idle + rec masters for the jewel; single cassette layer pack.

### 14. Easiest hit-target format for Record and Volume

Include in `Diane-cassette-layout.json` **and** mirror spots for the full machine in the same file (or `Diane-hits.json`):

```json
{
  "masterSize": { "w": 1410, "h": 3072 },
  "plateSize": { "w": 720, "h": 1080 },
  "cassetteWindow": { "x": 0.0, "y": 0.0, "w": 0.0, "h": 0.0 },
  "recordControl": { "x": 0.0, "y": 0.0, "w": 0.0, "h": 0.0 },
  "volumeControl": { "x": 0.0, "y": 0.0, "w": 0.0, "h": 0.0 },
  "recLamp": { "x": 0.0, "y": 0.0, "w": 0.0, "h": 0.0 },
  "reelLeft": {
    "centerX": 0.35,
    "centerY": 0.42,
    "diameter": 0.36
  },
  "reelRight": {
    "centerX": 0.35,
    "centerY": 0.68,
    "diameter": 0.36
  },
  "pivot": "imageCenter",
  "notes": "All machine spots normalised 0–1 of 1410×3072. Reel centres normalised 0–1 of plate."
}
```

Normalised fractions beat raw pixels (skin aspect-fills). Minimum hit size Cursor will expand to ~44–52 pt for touch.

**No pause control. No illustrated Action Button spots.**

### 15. Anything else for cleaner integration

1. Lock **Diane-idle** master geometry before finalising reel centres (measure window, then snap plate).  
2. Supply a flat **preview composite** `Diane-cassette-preview.png` (all layers flattened, reels at rest) for eyeballing alignment.  
3. Keep left/right reel art **visually distinct** (tape pack amount) so rotation reads; identical discs look fake.  
4. Studio wash behind machine remains `#F3EDE4`. Inside well: dark charcoal, not pure black if possible.  
5. Do not redesign machines in this pack. Kate/GG own look; this brief is implementation only.

---

## Motion recommendations (Cursor will implement)

| Parameter | Recommendation |
| --- | --- |
| Direction | Top-of-window view, portrait microcassette: **left reel clockwise, right reel counter-clockwise** (or reverse as a pair). Must look like tape feeding, not both spinning the same way. |
| Angular speed | Recording: **~140–160 deg/s** (~23–27 RPM). Subtle. Not toy-fast. |
| Left vs right speed | **Same angular speed** by default. Optional ±3% variance only if it still reads as linked tape; prefer identical for v1. |
| Idle | **0** rotation. Hold last angle (do not snap to 0). |
| Start / stop | Ease ~**0.35 s** ease-in on start, ~**0.5 s** ease-out on stop (inertia, not linear cut). |
| Continuity | Keep current angle when stopping; resume from that angle on next record (no loop reset pop). |
| Secondary motion | Optional: **0.3–0.6 px** slow sine on whole cassette group (period ~2.5 s) only while recording. Easy to kill if noisy. No bounce, no glow pulses on reels. |
| LED | Soft opacity pulse OK on jewel if code-driven; painted stills preferred. |
| Frame feel | Aim for continuous CATransform3D/rotation; avoid stepped 8 fps looks. |

Premium = quiet mechanics. If you notice it as “an animation,” slow it down.

---

## Delivery order

1. Kate/GG: final Diane master look (no Action Button art).  
2. GG: `Diane-idle.png` / `Diane-rec.png` @ 1410×3072 + window alpha + hits JSON.  
3. GG: cassette layer pack + `Diane-cassette-layout.json` + preview.  
4. Cursor: replace `AVPlayerLayer` path with layered cassette view; wire Record / Volume / lamp.  
5. Reuse architecture; new artwork only for Cooper / Palmer / Earle.

---

## Temporary bridge

Until layers ship, Cursor may keep or rotate the existing `CassetteLoop.mp4` under the alpha hole for layout tests. Final path is layers, not video.
