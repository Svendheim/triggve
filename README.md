# Trigger

A lightweight, zero-latency REAPER JSFX drum replacement and sample triggering plugin designed for Linux and cross-platform REAPER environments.

`Trigger` monitors incoming audio transients on a track, calculates peak velocity, and triggers samples from a multi-slot round-robin pool with randomization and no-immediate-repeat logic.

## Features

- **Audio Transient Detection**: Real-time envelope follower and peak threshold detection with customizable sensitivity and retrigger suppression.
- **8-Slot Sample Pool**: Dedicated WAV sample loading slots per instance.
- **Smart Round-Robin**: Randomized voice cycling preventing the same sample from triggering twice consecutively (machine-gun effect mitigation).
- **Polyphonic Playback**: Independent voice allocation allowing sample tails to ring out naturally without artificial clipping.
- **Dynamic Velocity Scaling**: Maps audio transient dynamics accurately to sample playback gain.

## Installation

1. Open REAPER.
2. Navigate to **Options** > **Show REAPER resource path in explorer/finder**.
3. Copy the `Trigger` JSFX file into your `Effects/` directory (or a custom subfolder like `Effects/DrumTools/`).
4. In REAPER's FX browser, press `F5` to scan for new plugins, or search for `Trigger`.

## Development & Roadmap

- [ ] v0.1: Initial architecture, agent instructions (`AGENTS.md`), and core scope
- [ ] v0.2: Core peak detection, hysteresis thresholding, and trigger pulse generation
- [ ] v0.3: JSFX sample buffer loading and polyphonic voice manager
- [ ] v0.4: Round-robin shuffle logic and GUI controls (threshold, retrigger time, gain)

## License

MIT
