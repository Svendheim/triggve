# Trigger

A lightweight, low-latency REAPER JSFX drum replacement and sample triggering plugin designed for Linux and cross-platform REAPER environments.

`Trigger` monitors incoming audio transients on a track, estimates hit velocity from the envelope, and plays a sample from an 8-slot pool. Slots can be filled by drag & drop and are cycled with **Single**, **Round-robin**, or **Random (no immediate repeat)** selection. By default the dry input is muted, so the plugin acts as a full drum replacement.

## Features

- **Audio Transient Detection**: Real-time envelope follower with configurable attack/release, threshold, hysteresis, and retrigger holdoff.
- **8-Slot Sample Pool**: Drag & drop WAV files onto slots; per-slot loaded indicator and length / channels / rate readout.
- **Easy Unloading**: Right-click a slot, click its `x`, or press **Clear All**.
- **Project Persistence**: Loaded file paths are stored with the project via `@serialize` and re-opened on reload.
- **Selection Modes**:
  - **Single (slot 1)** — always the first slot.
  - **Round-robin** — cycles through loaded slots in order, wrapping and skipping empties.
  - **Random** — uniform pick among loaded slots, never the same as the previous hit.
- **Polyphonic Playback**: 16 independent voices so sample tails ring out naturally without hard clipping.
- **Dynamic Velocity Scaling**: Maps transient envelope level linearly to sample playback gain.
- **Input Pass-through Toggle**: Mix the dry signal back in, or leave it muted for full replacement.
- **Output Safety & Anti-Click**: A soft-clip ceiling guarantees the output never exceeds 0 dBFS, and a short transport-stop fade prevents pops when stopping mid-sample.

## Controls

| # | Control | Default | Range | Notes |
|---|---------|---------|-------|-------|
| 1 | Threshold (dB) | −18 | −60 … 0 | Level the envelope must cross to fire. |
| 2 | Envelope Attack (ms) | 1 | 0.1 … 50 | Envelope follower attack. |
| 3 | Envelope Release (ms) | 5 | 1 … 45 | Envelope follower release; also sets how fast the detector re-arms. |
| 4 | Retrigger Holdoff (ms) | 20 | 1 … 100 | Minimum time between triggers. |
| 5 | Hysteresis (dB) | 6 | 0 … 24 | How far the envelope must fall below threshold before re-arming. |
| 6 | Sample Level | 1.0 | 0 … 1 | Output gain for triggered samples. |
| 7 | Pass Input (1 = on) | 0 | 0 … 1 | 0 = full replacement (input muted); 1 = mix dry input with samples. |
| 8 | Sample Selection | Random | Single / Round-robin / Random | How the next sample is chosen. |

## Installation

1. Open REAPER.
2. Navigate to **Options** > **Show REAPER resource path in explorer/finder**.
3. Copy `Trigger.jsfx` into your `Effects/` directory (or a custom subfolder like `Effects/DrumTools/`).
4. In REAPER's FX browser, press `F5` to rescan, then search for **Trigger**.

## Usage

1. Insert `Trigger` on the track carrying the drum audio.
2. Open the plugin's **floating FX window** (not the TCP-embedded view) so drag & drop works.
3. Drag a WAV file onto a slot. Repeat for as many slots as you want to use.
4. Pick a **Sample Selection** mode and adjust Threshold so hits fire reliably without false triggers.
5. Leave **Pass Input** at `0` for replacement, or set it to `1` to blend the dry drum.

Notes:
- Samples are resampled to the project sample rate on load and capped at **4 seconds** each.
- Loading happens only in `@gfx` / `@slider` / `@serialize` — never in `@sample` — keeping the audio thread safe.
- After editing the JSFX on disk, reload the FX (`F5` or reopen) to pick up changes.

## Development & Roadmap

- [x] v0.1: Initial architecture, agent instructions (`AGENTS.md`), and core scope
- [x] v0.2: Core peak detection, hysteresis thresholding, and trigger pulse generation
- [x] v0.3: JSFX sample buffer loading (drag & drop), unload, and project persistence
- [x] v0.31: Polyphonic 16-voice playback, linear velocity, full-replacement default
- [x] v0.4: Single / Round-robin / Random selection modes, larger readable GUI
- [x] v0.4.1: Output safety ceiling (soft-clip) + click-free transport stop
- [ ] Settings pass: review detector defaults and velocity behavior (possibly threshold-relative)
- [ ] Onset/derivative detection to decouple retriggering from envelope release time
- [ ] Optional: longer no-immediate-repeat window and/or per-slot weighting

## License

Not decided, but GPL or MIT I guess.
