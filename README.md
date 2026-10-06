# Triggve

<p align="center">
  <img src="triggve.jpg" alt="Triggve logo" width="420">
</p>

A lightweight, low-latency REAPER JSFX drum replacement and sample triggering plugin for Linux and cross-platform REAPER environments. Current version: **beta2**.

`Triggve` monitors incoming audio transients on a track, estimates hit velocity from the input peak, and plays a sample from a 32-slot pool split into **four velocity layers** — **Ghost**, **Low**, **Medium**, and **Hard**. Each layer holds up to 8 samples; a hit is classified into a layer from its peak level, and the sample is cycled within that layer with **Single**, **Round-robin**, or **Random (no immediate repeat)** selection. By default the dry input is muted (**Mix** = 1), so the plugin acts as a full drum replacement.

## Features

- **Audio Transient Detection**: Real-time envelope follower with configurable attack/release, threshold, hysteresis, and retrigger holdoff.
- **4 Velocity Layers**: Ghost / Low / Medium / Hard, each with up to **8 slots** (32 total). The layer is chosen from the hit's peak level via three configurable dB boundaries above the Threshold.
- **32-Slot Sample Pool**: Drag & drop WAV files onto slots; per-slot loaded indicator and length / channels / rate readout, arranged in a layer-per-row grid.
- **Easy Unloading**: Right-click a slot, click its `x`, or press **Clear All**.
- **Project Persistence**: Loaded file paths are stored with the project via `@serialize` and re-opened on reload.
- **Selection Modes** (per layer):
  - **Single** — always the first loaded slot in the layer.
  - **Round-robin** — cycles through loaded slots in order, wrapping and skipping empties.
  - **Random** — uniform pick among loaded slots, never the same as the previous hit.
- **Polyphonic Playback**: 96 independent voices so sample tails ring out naturally without hard clipping or voice stealing.
- **Dynamic Velocity Scaling** (off by default): plays each sample at the hit's **peak level** (measured over a short window, not at the threshold crossing), so triggered samples match the source loudness. Leave it off when your layer samples already carry the right loudness.
- **Makeup Output Gain**: A ±24 dB output gain to match quiet sources, protected by the soft-clip ceiling.
- **Wet/Dry Mix**: A linear blend between the dry input and triggered samples (0 = original only, 1 = samples only), so you can dial in exactly how much of the source to keep.
- **Output Safety & Anti-Click**: A soft-clip ceiling guarantees the output never exceeds 0 dBFS, and a short transport-stop fade prevents pops when stopping mid-sample.
- **Compact Custom UI**: All controls are drawn inside the plugin window, two per row, instead of REAPER's full-width slider strip. They stay fully automatable and are saved with the project.

<p align="center">
  <img src="triggve-ui.png" alt="Triggve UI" width="640">
</p>

## Controls

All twelve controls are drawn in the plugin's own window, two per row (the two dropdowns sit at the bottom). They are hidden REAPER parameters, so they remain automatable and are stored with the project. Drag a control to set it, or hover it and use the mouse wheel (hold **Shift** for coarser steps).

| # | Control | Default | Range | One-line summary |
|---|---------|---------|-------|------------------|
| 1 | Threshold (dB) | −18 | −60 … 0 | How loud a hit must be to trigger. |
| 2 | Envelope Attack (ms) | 1 | 0.1 … 50 | How quickly the detector reacts to a rising hit. |
| 3 | Envelope Release (ms) | 5 | 1 … 45 | How quickly the detector lets go after a hit (also sets re-arm speed). |
| 4 | Retrigger Holdoff (ms) | 20 | 1 … 100 | Minimum time between two triggers. |
| 5 | Hysteresis (dB) | 6 | 0 … 24 | How far the signal must drop before the detector can fire again. |
| 6 | Mix | 1.0 | 0 … 1 | Blend of dry input vs. triggered samples. |
| 7 | Dynamic Velocity | Off | Off / On | Velocity scaling from hit strength. Off = samples play at their original volume. |
| 8 | Sample Selection | Random | Single / Round-robin / Random | Which loaded slot plays next within the chosen layer. |
| 9 | Output Gain (dB) | 0 | −24 … +24 | Makeup gain for the triggered samples. |
| 10 | Ghost / Low boundary (dB) | +3 | 0 … 48 | How far above Threshold still counts as a Ghost hit. |
| 11 | Low / Medium boundary (dB) | +9 | 0 … 48 | Boundary between Low and Medium hits. |
| 12 | Medium / Hard boundary (dB) | +15 | 0 … 48 | Boundary between Medium and Hard hits. |

### How the detector works
The plugin follows the input with an **envelope**: it rises quickly (Attack) when a hit arrives and falls slowly (Release) when it ends. A trigger fires when the envelope crosses the **Threshold**. After firing, the detector is "disarmed" and only re-arms once the envelope falls below *Threshold minus Hysteresis*; the **Holdoff** also enforces a minimum gap between triggers. Release and Hysteresis together control how fast the next hit can be detected.

### How velocity layers work
A hit's **peak level** is measured over a short (~8 ms) window, converted to dBFS, and compared against three boundaries derived from the Threshold: `Threshold + slider 10`, `Threshold + slider 11`, and `Threshold + slider 12`. The result picks a layer:

- **Ghost** — below the Ghost/Low boundary.
- **Low** — between the Ghost/Low and Low/Medium boundaries.
- **Medium** — between the Low/Medium and Medium/Hard boundaries.
- **Hard** — at or above the Medium/Hard boundary.

The plugin then chooses a sample **within that layer** using the Sample Selection mode. If the chosen layer has no samples loaded, it falls back to the nearest *louder* loaded layer, then the nearest softer one, so a hit is never dropped. Each layer keeps its own round-robin/random state, and up to 8 samples per layer give strong protection against machine-gunning.

> **Known trade-off:** that ~8 ms measurement window is also the extra latency added to every triggered sample. It is currently fixed in code (`vel_window` in `Triggve.jsfx`) and may become shorter, adjustable, or adaptive later.

### What each slider does

**1. Threshold (dB)** — detection sensitivity.
The level the envelope must reach to fire. **Lower** = more sensitive (quiet/ghost notes trigger), **higher** = only strong hits trigger. Range −60 … 0 dB. Tune it so real hits fire but bleed/tails don't.

**2. Envelope Attack (ms)** — how fast the detector *reacts* to a rise.
**Lower** = snappier tracking of sharp transients; **higher** = smoother, ignoring very short clicks/noise. This shapes *detection only* — it does not change the played sample. Default 1 ms.

**3. Envelope Release (ms)** — how fast the detector *lets go* after a hit.
This is the main control over **retrigger speed**: a shorter release drops below the re-arm point faster, allowing rapid successive hits. **Too short** and a long/ringy hit may re-fire. Default 5 ms.

**4. Retrigger Holdoff (ms)** — a hard minimum gap between triggers.
After a trigger, the plugin ignores further triggers for this long. It prevents double-triggers/machine-gunning independently of Release. Lower it for very fast rolls; raise it if a single hit fires twice. Default 20 ms.

**5. Hysteresis (dB)** — the re-arm margin.
After a hit, the envelope must fall *this far below* the Threshold before the detector re-arms. **Larger** = more robust against re-firing on decay/noise; **smaller** = more sensitive to closely spaced hits. Default 6 dB.

**6. Mix** — dry/wet blend.
`0` = original drum only, `1` = triggered sample only (full replacement), in between mixes both linearly. Default `1`. Use it to keep some of the source or to audition the samples.

**7. Dynamic Velocity** — optional gain scaling by hit strength.
**On** plays each sample at the hit's peak level; **Off** plays every sample at its original volume. Default **Off**, which is usually right when your layer samples already have the loudness you want — enabling it on top of velocity layers applies a second, redundant scaling.

**8. Sample Selection** — which loaded slot plays next, within the layer that was chosen for the hit.
- **Single** — always the first loaded slot in the layer.
- **Round-robin** — cycles through that layer's loaded slots in order (skips empty slots, wraps at the end).
- **Random** — picks a loaded slot in that layer at random, **never the same as the previous hit** (avoids machine-gun repetition).
If the layer has only one loaded slot, every mode plays that slot. Default **Random**.

**9. Output Gain (dB)** — makeup gain for the samples.
Applied to the triggered samples (not the dry input) before the safety ceiling. Use it to match the source loudness if your samples are quieter. Range ±24 dB. The soft-clip prevents the output from exceeding 0 dBFS even when boosted. Default 0 dB.

**10–12. Layer boundaries (dB above Threshold)** — where one velocity layer ends and the next begins.
These are offsets from the **Threshold**, so the whole scheme moves with your sensitivity setting. **Slider 10** = Ghost/Low, **slider 11** = Low/Medium, **slider 12** = Medium/Hard. Defaults +3 / +9 / +15 dB. A hit below `Threshold + slider 10` is a Ghost; a hit at or above `Threshold + slider 12` is Hard. Tune them by playing soft ghost notes and full hits and watching which layer lights up.

### Signal flow
```
input ──► detector (Attack/Release/Threshold/Hysteresis/Holdoff) ──► trigger
                                                                      │
                                                                      ▼
                       velocity window (~8 ms) ──► layer (Ghost/Low/Medium/Hard)
                                                                      │
                                                                      ▼
                 slot pool, within layer (Selection) ──► voice ──► × Output Gain ──► soft-clip
                                                                                       │
input (dry) ─────────────────────────────────────────────────────────────────► Mix ◄───┘
                                                                                 │
                                                                                 ▼
                                                                              output
```


## Installation

1. Open REAPER.
2. Navigate to **Options** > **Show REAPER resource path in explorer/finder**.
3. Copy `Triggve.jsfx` into your `Effects/` directory (or a custom subfolder like `Effects/DrumTools/`).
4. In REAPER's FX browser, press `F5` to rescan, then search for **Triggve**.

## Usage

1. Insert `Triggve` on the track carrying the drum audio.
2. Open the plugin's **floating FX window** (not the TCP-embedded view) so drag & drop works.
3. Drag a WAV file onto a slot row. Fill the **Ghost / Low / Medium / Hard** rows with samples for each hit strength — up to 8 per layer.
4. Adjust **Threshold** so hits fire reliably without false triggers, then tune the three **layer boundaries** (10–12) so soft ghost notes land in Ghost and full hits land in Medium/Hard. The left-hand row highlight and the **Last** readout show which layer fired.
5. Pick a **Sample Selection** mode (it applies within the chosen layer).
6. Set **Mix** to `1` for full replacement, or lower it to blend the dry drum back in.

Notes:
- Samples are resampled to the project sample rate on load and capped at **4 seconds** each.
- Loading happens only in `@gfx` / `@slider` / `@serialize` — never in `@sample` — keeping the audio thread safe.
- After editing the JSFX on disk, reload the FX (`F5` or reopen) to pick up changes.

## Roadmap

Triggve is now in **beta**. Versions progress **beta1 → beta2 → … → 1.0**. Pre-beta development history (v0.1–v0.5) is recorded in [CHANGELOG.md](CHANGELOG.md).

- [x] **beta1** — First beta: transient detector, 8-slot drag & drop pool, 96-voice playback, Single/Round-robin/Random selection, peak-accurate velocity, Output Gain, wet/dry Mix, soft-clip safety ceiling, click-free transport stop.
- [x] **beta2** — **Velocity layers**: Ghost / Low / Medium / Hard, up to 8 slots each (32 total), dB-boundary classification from the hit peak, per-layer Single/Round-robin/Random selection, layer-per-row GUI, Dynamic Velocity defaults off.
- [ ] **beta3** — TBD (candidates: tune or parameterise the fixed ~8 ms velocity window, onset/derivative detection, a separate rimshot/articulation detector, per-slot weighting/enable, longer no-repeat window).
- [ ] **1.0** — Stable release.

## License

Released under the [MIT License](LICENSE).
