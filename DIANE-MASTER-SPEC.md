# Diane master art specification

**Authority:** Diane project sources in this Studio folder.  
**Audience:** GG (production masters), Adele + Kate (direction), Cursor (integration).  
**Scope:** Diane app only. Three machines: Diane, Cooper, Palmer.  
**Date:** 20 Aug 2026.  
**Status:** Living spec. Geometry below is what the shipping app uses today. GG may propose a tighter master; once Adele approves it, code spots update to match and that geometry becomes sacred.

**Production lock (20 Aug 2026):** Same hard bar as MyTablo. Soft / approximate artwork is not acceptable. Baseline below, not a target to rediscover. Sent to GG in the Diane GG thread.

**Idle skin lock (20 Aug 2026, Adele + GG):** Image 2 style is the locked production direction for all machines.

- **One idle skin per machine only** this pass.
- Cassette aperture completely empty, **true alpha 0**. No cassette artwork baked into the skin.
- Cassette art / animation lives **underneath** as separate assets.
- Later **rec twin** is pixel-identical except recording lamp state.
- With-tape proofs (Image 1 style) are **reference only**. They do not ship as skins.
- Order: **Diane → Earle → Cooper → Palmer**. Each `*-idle.png` @ 1410×3072 RGBA, `#F3EDE4` wash, locked body from the approved contact sheet. Cooper: Record only, no Stop; same machine dimensions.
- Scope note: app ships Diane / Cooper / Palmer today; Earle is produced in this pass for the family lock.

---

## 1. Product in one line

Diane is a dictaphone you talk into. Open, talk, done. The cassette is the brand. Twin Peaks mood, cousin Diane, no borrowed fashion or manufacturer names.

Protect the interaction: speaking into a machine, not typing into an empty field.

---

## 2. Creative brief (from GG, locked as intent)

Treat each machine as **industrial design**, not a pretty picture.

- Care about every button, cassette-window size, bezel depth, speaker perforations, screws, seams, counters, switches, materials.
- Once a machine is approved, **geometry is sacred**. Recording state must not move buttons or change case width.
- Three kinds of desirability, same universe:
  - **Diane** — exquisitely manufactured (gold).
  - **Cooper** — beautifully utilitarian (quiet black, silver hardware).
  - **Palmer** — genuinely aged (worn metal dictaphone).

Start with **Diane**. Get one machine exceptional. Lock the master. Carry that quality to Cooper and Palmer.

Do **not** make them generically shinier or luxury. No real brand logos. No fashion-house names.

### Quality bar (locked with MyTablo)

- Photorealistic materials. Physically believable metal, plastic, glass, worn paint, screws, seams, speaker mesh.
- No CGI smoothness. No fashion-house logos. No real manufacturer brands.
- Idle and recording must share the same case, buttons, and window. Only lamp / energy may change.

### Production files vs proofs

- Proof sheets / concepts are for review only.
- Final files arrive **ready for the app**. Adele and Kate will not cut, mask, or upscale.
- Never leave a white matte, halo, cutout residue, or baked background where transparency is required.
- Never deliver a small proof and call it the master. Genuine native resolution, or multi-plate assembly into the true master size. **No basic upscale.**

### Widgets (next pass, same bar)

Home-screen widgets need sorting to this standard too. No soft composites, no leftover white plates, no “good enough” crops. Widget art must be genuine resolution for the widget size, clean edges, and match the machine’s locked geometry / brand mood. Do not invent a new Diane look for widgets. Do after home skins are locked.

### Process (locked)

1. One hero approval proof for **Diane idle** (material, light, geometry).
2. After approval: genuine production master at **1410 × 3072** with true cassette-window alpha.
3. Then Diane rec (same geometry).
4. Only then Cooper and Palmer.
5. Widget artwork after the home skins are locked.

GG confirms understanding, then proposes the first Diane idle proof direction before generating.

### Diane idle proof direction (approved Adele, 20 Aug 2026)

Confirmed by GG. Approved to proceed to first proof.

- Near-orthographic, front-facing fictional vintage dictaphone
- Warm cream moulded ABS body with fine texture and subtle manufacturing variation
- Restrained satin-gold plated hardware, never glossy “luxury” gold
- Mechanically rational top controls, side wheel, Record and Pause keys
- Engineered speaker perforation grid with credible depth
- Applied or inset Diane identity, integrated into the construction
- Proper two-part shell, seams, fasteners, cassette-door latch and assembly logic
- Layered cassette chamber: gold bezel, cream door structure, smoked glass, gasket, inner-wall shadows and exact video aperture
- Soft product-photography lighting on `#F3EDE4`
- Tiny deterministic imperfections shared by every later state
- Composition tested against the real idle, recording and safe-area overlays
- No UI, phone frame or baked cassette content in the proof

The first proof establishes geometry, material response and light, not merely mood. Once approved, that exact model and camera become the 1410×3072 RGBA production master. Recording differs only through physical Record lens illumination. Picker (800×1000) and widgets derive from the locked Diane model.

---

## 3. How art is used in the app (integration contract)

| Layer | What happens |
| --- | --- |
| Studio wash | Full-screen colour behind the skin. Light: `#F3EDE4`. |
| Cassette video | Looped MP4 sits **under** the PNG, only visible through a **true alpha hole** in the cassette window. File: `Diane/Video/CassetteLoop.mp4`. |
| Skin still | Full-bleed PNG, aspect-fill, centred. Idle and (where provided) recording stills swap with no layout change. |
| Rec lamp | Prefer **painted into the recording still**. Code glow is only a fallback (Palmer today). |
| Pause | Invisible hit target on Pause / Stop key for Diane and Cooper. Palmer has no pause spot yet. |
| Press feel | Slight scale (~1.01) while rolling. Geometry must survive that nudge. |

**Hard rule:** The cassette window in every full-bleed skin must be **real transparency** (alpha = 0), not a painted black rectangle. Video shows through the hole.

---

## 4. Canvas and technical deliverables

### 4.1 Full-bleed home skins (primary)

| Spec | Value |
| --- | --- |
| Pixel size | **1410 × 3072** (portrait, ~9:19.5, matches live assets) |
| Colour | sRGB |
| Format | PNG-24 + alpha (RGBA) |
| Framing | Machine fills the canvas. Soft studio falloff into `#F3EDE4` at edges if needed. No UI chrome, no status bar, no fake phone bezel. |
| Safe thinking | Home stage is full screen. Important hardware stays in the central ~70% height so Dynamic Island / home indicator do not eat it. |

**Per machine, deliver:**

1. `{Name}-idle.png` — resting state  
2. `{Name}-rec.png` — recording state (same geometry; lamp on, maybe subtle energy; **nothing else moves**)  
3. Optional later: `{Name}-pause.png` if Pause should look mechanically different

### 4.2 Settings picker cards

| Spec | Value |
| --- | --- |
| Pixel size | **800 × 1000** |
| Content | Crop / framed portrait of the machine on studio wash |
| Format | PNG, alpha OK |

### 4.3 Cassette shells (secondary, letters / tape colour)

Already in app as `TapeShell*` at **1536 × 1024**. Out of scope for first master pass unless GG wants to unify. Not blocking Diane / Cooper / Palmer faces.

### 4.4 App icon

`AppIcon` 1024 × 1024 exists. Separate pass; not required to unlock skin masters.

### 4.5 Naming (product vs asset file)

Product names and current asset filenames differ (legacy). Prefer **new GG files** named by product; Cursor will map into Assets.

| Product name | Mood | Current asset stem (legacy) |
| --- | --- | --- |
| **Diane** | The gold one | `SkinCooper` / `SkinCooperRec` / `SkinCooperPick` |
| **Cooper** | Quiet black, silver hardware | `SkinNoir` / `SkinNoirRec` / `SkinNoirPick` |
| **Palmer** | Worn metal dictaphone | `SkinSteel` / (no Rec yet) / `SkinSteelPick` |

Suggested GG drop names:

```
Diane-idle.png
Diane-rec.png
Diane-pick.png
Cooper-idle.png
Cooper-rec.png
Cooper-pick.png
Palmer-idle.png
Palmer-rec.png
Palmer-pick.png
```

---

## 5. Sacred geometry (live app coordinates)

All spots are **normalised 0–1** of the skin image (x, y, width, height). Source: `Diane/Models/Models.swift`.

When GG locks a master, return updated fractions for the true window and keys. Adele approves → code updates → then sacred.

### 5.1 Diane (gold)

| Spot | x | y | w | h | Notes |
| --- | --- | --- | --- | --- | --- |
| Cassette window | 0.215 | 0.265 | 0.570 | 0.142 | Must be alpha hole |
| Pause control | 0.755 | 0.539 | 0.090 | 0.046 | Hit target only |
| Rec lamp | — | — | — | — | Painted in `*-rec` still |

### 5.2 Cooper (black)

| Spot | x | y | w | h | Notes |
| --- | --- | --- | --- | --- | --- |
| Cassette window | 0.2319 | 0.2441 | 0.5170 | 0.1514 | Must be alpha hole |
| Pause control | 0.740 | 0.545 | 0.090 | 0.048 | Hit target only |
| Rec lamp | — | — | — | — | Painted in `*-rec` still |

### 5.3 Palmer (steel)

| Spot | x | y | w | h | Notes |
| --- | --- | --- | --- | --- | --- |
| Cassette window | 0.2000 | 0.3984 | 0.5723 | 0.1348 | Must be alpha hole |
| Pause control | — | — | — | — | None in code yet |
| Rec lamp | derived | ~window top centre | tiny | tiny | Code overlay today; prefer paint into `Palmer-rec` |

`fillScale` = 1, `fillOffsetY` = 0 for all three.

---

## 6. Animation and motion (what art must support)

| State | Visual | Art implication |
| --- | --- | --- |
| Idle | Still skin, video paused / not rolling | Clean idle still |
| Recording | Reels roll in window via video; optional painted rec lamp | Hole stays exact; rec still identical silhouette |
| Pause | Listening paused; hit Pause key | Key must stay discoverable; no layout shift |
| Press | ~1% scale | No fragile edge crops |

**Reel video:** one shared loop under all skins (`CassetteLoop.mp4`). Window aspect and bezel must frame that loop cleanly. If GG later wants per-skin reel colour / grit, that is a second video pass, not required for v1 masters.

**Do not animate** by warping the case between idle and rec. Idle and rec are pixel-aligned twins.

---

## 7. Colour and studio

| Token | Hex | Use |
| --- | --- | --- |
| Studio / light bg | `#F3EDE4` | Behind skins, letter world |
| Ink | `#2C2824` | UI (not painted on machine unless lettering) |
| Accent gold | `#C4A36A` | UI accent; Diane metal may rhyme, not match flat |
| Rec | `#D23B32` | Lamp / recording cue |
| Pause | `#E39B3A` | Pause cue in UI chrome |

Machines may use richer materials than these flat tokens. Tokens are for UI harmony, not a palette lock on the hardware paint.

---

## 8. Reference pack (what exists in this repo)

### In app (shipping)

- `Diane/Assets.xcassets/SkinCooper*.imageset/` — Diane idle / rec / pick  
- `Diane/Assets.xcassets/SkinNoir*.imageset/` — Cooper idle / rec / pick  
- `Diane/Assets.xcassets/SkinSteel*.imageset/` — Palmer idle / pick (no Rec)  
- `Diane/Video/CassetteLoop.mp4` — reel loop under the window  

### Brand / mood (`brand/`)

- `reference-cooper.png`, `reference-noir.png`, `reference-steel.png`  
- `diane-tape.png`, `IMG_1400.JPG` … photo refs  
- `cooper-window.png`, `noir-window.png`, `steel-window.png`  
- `video/kate-diane-wireframe.mov`, `video/cassette-loop.mp4`  
- `skins-previous/` — older full bleeds  

### Incoming (Kate, not yet production masters)

- `Incoming/Cooper.png` — 766×1719, **no alpha** (concept, not ship size)  
- `Incoming/Palmer.png` — 768×1376, **no alpha**  
- `Incoming/Kate-black-Diane-lettering.MOV`  

These show personality. They are **not** the canvas size or alpha contract.

### Product brief

- `BRIEF.md` — product rules, skins one-liners, what Diane is not  

---

## 9. Known gaps (for GG audit)

1. **Palmer** has no painted rec still; code draws a tiny lamp.  
2. **Palmer** pause key has no hit spot.  
3. **Incoming** Cooper / Palmer are wrong size and lack window alpha.  
4. Live **Palmer** window hole is irregular vs the rectangular code spot (centre transparent; rect corners can still be opaque). Master should make a clean rectangular (or intentional shaped) hole and report exact fractions.  
5. Asset filenames still say Cooper/Noir/Steel while product says Diane/Cooper/Palmer.  
6. No locked industrial blueprint yet. That is GG’s first job after reviewing screenshots + this pack.

---

## 10. Proposed production order

Aligned with the 20 Aug production lock:

1. **Audit** this pack + Adele’s UI screenshots. List accessible vs missing.  
2. Propose **Diane idle** proof direction (material, light, geometry). No mass generation yet.  
3. Adele + Kate approve hero proof.  
4. Genuine **Diane** idle master at 1410×3072 with true window alpha. Then Diane rec.  
5. Drop into Simulator; Cursor wires spots; iterate until world class.  
6. Clone process for **Cooper**, then **Palmer**.  
7. Picker crops derived from masters.  
8. Widgets last, same bar, same machines.

---

## 11. What Adele will send GG

- This file: `DIANE-MASTER-SPEC.md`  
- Access to Studio/Diane (`brand/`, `Incoming/`, live Assets)  
- **Screenshots of current UI** (home idle, home recording, settings skin picker, each skin if possible)

### Received 20 Aug 2026 (Palmer)

Saved under `brand/ui-shots/`:

- `Palmer-idle.png` — home idle, “Tap the tape.”  
- `Palmer-rec.png` — recording, transcript + That’s it + REC card  
- `Palmer-rec.mp4` — screen recording of Palmer rolling  

Still needed for GG’s full audit: same idle + rec (and short clip if easy) for **Diane** and **Cooper**, plus settings skin picker.

---

## 12. Definition of done (one machine)

- [ ] Idle and rec are identical geometry (pixel-aligned)  
- [ ] Cassette window is true alpha; reels read clearly  
- [ ] Rec lamp is intentional (painted preferred)  
- [ ] Pause / key hit areas documented if interactive  
- [ ] Machine feels like a designed object, not a prompt collage  
- [ ] Sits on `#F3EDE4` without a floating cardboard edge  
- [ ] Adele signs off in Simulator at craft bar (Oura / Apple grade)

---

## 13. Copy constraints for lettering on machines

If any machine carries the word Diane or labels:

- UK English  
- No em dashes in UI-facing copy  
- Do not invent fake corporate logos that look like real brands  

---

*End of master spec. Update this file when sacred geometry is locked from GG’s approved masters.*
