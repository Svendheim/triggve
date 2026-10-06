# Changelog

All notable changes to **Triggve** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project uses a beta versioning scheme (`beta1`, `beta2`, … → `1.0`).

## [beta2] — 2026-10-06

### Added
- **Velocity layers** — Ghost / Low / Medium / Hard, selected from each hit's measured peak.
- **32-slot sample pool** (4 layers × up to 8 slots), arranged in a layer-per-row grid.
- **Layer boundary sliders** (sliders 10–12) defining the dB offsets above Threshold where each layer begins, with fallback to the nearest loaded layer when a layer is empty.
- **Per-layer selection state** — Single / Round-robin / Random now cycle within the chosen layer, giving up to 8 samples per hit strength.
- **Deferred velocity measurement** — a short (~8 ms) window captures the true hit peak before the layer and sample are chosen.
- **Dynamic Velocity** toggle (off = samples play at their original volume).

### Changed
- **Dynamic Velocity** now defaults to **Off**, since velocity layers already carry loudness.
- Sample capacity raised from 8 to **32** slots; `maxmem` raised to 120M slots to cover high sample rates.
- GUI widened to a 4×8 layer grid with row labels showing each layer's velocity range.

## [beta1] — 2026-10-05

First beta release. **Triggve** is a REAPER JSFX audio-to-sample drum trigger for Linux and cross-platform REAPER.

### Added
- **Real-time transient detector** with controls for Threshold, Envelope Attack, Envelope Release, Retrigger Holdoff, and Hysteresis.
- **8-slot sample pool** with drag & drop loading, plus unloading via right-click, a per-slot `x`, or **Clear All**.
- **Per-slot readout** (length, channels, sample rate); samples are resampled to the project rate and capped at 4 seconds.
- **Project persistence** of sample paths via `@serialize`, so loaded slots survive project reloads.
- **96-voice polyphonic playback** with oldest-voice stealing as a fallback.
- **Peak-accurate velocity** — each sample plays at the hit's peak level (measured over a short window), so triggered samples match the source loudness.
- **Selection modes** — Single (slot 1), Round-robin, and Random (no immediate repeat).
- **Output Gain** (−24 … +24 dB makeup) and a **soft-clip safety ceiling** so the output never exceeds 0 dBFS.
- **Wet/dry Mix** — a linear blend between the dry input and the triggered samples.
- **Click-free transport stop** via a short fade.
- **Custom GUI** — a readable slot grid showing loaded state and the last-played slot.

### Changed
- Defaults to **full replacement** (Mix = 1) rather than mixing the source back in.
- Velocity now uses the input **peak** instead of the threshold-crossing envelope value, fixing quiet playback.

### Removed
- Redundant **Sample Level** slider (use **Output Gain** instead).

### Pre-beta history
Development milestones before beta1: v0.1 (architecture), v0.2 (detection), v0.3 (sample loading + persistence), v0.31 (polyphonic playback, defaults), v0.4 (selection modes + GUI), v0.4.1 (safety ceiling + anti-click stop), v0.5 (peak velocity, Output Gain, wet/dry Mix, 96 voices).

[beta2]: #beta2--2026-10-06
[beta1]: #beta1--2026-10-05
