# Triggve

**Hit Happens.**

A lightweight, low-latency REAPER JSFX drum replacement and sample triggering plugin for Linux and cross-platform REAPER environments. Current version: **beta1**.

`Triggve` monitors incoming audio transients on a track, estimates hit velocity from the input peak, and plays a sample from an 8-slot pool. Slots can be filled by drag & drop and are cycled with **Single**, **Round-robin**, or **Random (no immediate repeat)** selection. By default the dry input is muted (**Mix** = 1), so the plugin acts as a full drum replacement.

## Features

- **Audio Transient Detection**: Real-time envelope follower with configurable attack/release, threshold, hysteresis, and retrigger holdoff.
- **8-Slot Sample Pool**: Drag & drop WAV files onto slots; per-slot loaded indicator and length / channels / rate readout.
- **Easy Unloading**: Right-click a slot, click its `x`, or press **Clear All**.
- **Project Persistence**: Loaded file paths are stored with the project via `@serialize` and re-opened on reload.
- **Selection Modes**:
  - **Single (slot 1)** — always the first slot.
  - **Round-robin** — cycles through loaded slots in order, wrapping and skipping empties.
  - **Random** — uniform pick among loaded slots, never the same as the previous hit.
- **Polyphonic Playback**: 96 independent voices so sample tails ring out naturally without hard clipping or voice stealing.
- **Dynamic Velocity Scaling**: Plays each sample at the hit's **peak level** (measured over a short window, not at the threshold crossing), so triggered samples match the source loudness.
- **Makeup Output Gain**: A ±24 dB output gain to match quiet sources, protected by the soft-clip ceiling.
- **Wet/Dry Mix**: A linear blend between the dry input and triggered samples (0 = original only, 1 = samples only), so you can dial in exactly how much of the source to keep.
- **Output Safety & Anti-Click**: A soft-clip ceiling guarantees the output never exceeds 0 dBFS, and a short transport-stop fade prevents pops when stopping mid-sample.

## Controls

| # | Control | Default | Range | One-line summary |
|---|---------|---------|-------|------------------|
| 1 | Threshold (dB) | −18 | −60 … 0 | How loud a hit must be to trigger. |
| 2 | Envelope Attack (ms) | 1 | 0.1 … 50 | How quickly the detector reacts to a rising hit. |
| 3 | Envelope Release (ms) | 5 | 1 … 45 | How quickly the detector lets go after a hit (also sets re-arm speed). |
| 4 | Retrigger Holdoff (ms) | 20 | 1 … 100 | Minimum time between two triggers. |
| 5 | Hysteresis (dB) | 6 | 0 … 24 | How far the signal must drop before the detector can fire again. |
| 6 | Mix | 1.0 | 0 … 1 | Blend of dry input vs. triggered samples. |
| 7 | Sample Selection | Random | Single / Round-robin / Random | Which loaded slot plays next. |
| 8 | Output Gain (dB) | 0 | −24 … +24 | Makeup gain for the triggered samples. |

### How the detector works
The plugin follows the input with an **envelope**: it rises quickly (Attack) when a hit arrives and falls slowly (Release) when it ends. A trigger fires when the envelope crosses the **Threshold**. After firing, the detector is "disarmed" and only re-arms once the envelope falls below *Threshold minus Hysteresis*; the **Holdoff** also enforces a minimum gap between triggers. Release and Hysteresis together control how fast the next hit can be detected.

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

**7. Sample Selection** — which loaded slot plays next.
- **Single (slot 1)** — always slot 1.
- **Round-robin** — cycles through loaded slots in order (skips empty slots, wraps at the end).
- **Random** — picks a loaded slot at random, **never the same as the previous hit** (avoids machine-gun repetition).
If only one slot is loaded, every mode plays that slot. Default **Random**.

**8. Output Gain (dB)** — makeup gain for the samples.
Applied to the triggered samples (not the dry input) before the safety ceiling. Use it to match the source loudness if your samples are quieter. Range ±24 dB. The soft-clip prevents the output from exceeding 0 dBFS even when boosted. Default 0 dB.

### Signal flow
```
input ──► detector (Attack/Release/Threshold/Hysteresis/Holdoff) ──► trigger
                                                                      │
                                                                      ▼
                              slot pool (Selection) ──► voice (peak velocity) ──► × Output Gain ──► soft-clip
                                                                                                      │
input (dry) ────────────────────────────────────────────────► Mix ◄──────────────────────────────────┘
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
3. Drag a WAV file onto a slot. Repeat for as many slots as you want to use.
4. Pick a **Sample Selection** mode and adjust Threshold so hits fire reliably without false triggers.
5. Set **Mix** to `1` for full replacement, or lower it to blend the dry drum back in.

Notes:
- Samples are resampled to the project sample rate on load and capped at **4 seconds** each.
- Loading happens only in `@gfx` / `@slider` / `@serialize` — never in `@sample` — keeping the audio thread safe.
- After editing the JSFX on disk, reload the FX (`F5` or reopen) to pick up changes.

## Roadmap

Triggve is now in **beta**. Versions progress **beta1 → beta2 → … → 1.0**. Pre-beta development history (v0.1–v0.5) is recorded in [CHANGELOG.md](CHANGELOG.md).

- [x] **beta1** — First beta: transient detector, 8-slot drag & drop pool, 96-voice playback, Single/Round-robin/Random selection, peak-accurate velocity, Output Gain, wet/dry Mix, soft-clip safety ceiling, click-free transport stop.
- [ ] **beta2** — TBD (candidates: onset/derivative detection, per-slot weighting/enable, longer no-repeat window).
- [ ] **beta3** — TBD.
- [ ] **1.0** — Stable release.

## License

Not decided, but GPL or MIT I guess.
