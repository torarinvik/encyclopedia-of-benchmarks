# Ptrdist YACR2 Maze1 dogleg routing

This package isolates one column's bounded `Maze1` dogleg choice from YACR2, the channel router. It preserves the pinned launcher's `-DTODD` branch order: try an upper dogleg to the left, then right, then a lower dogleg to the left, then right. Each candidate checks four inclusive segments against the existing vertical-plane occupancy map and accepts the route only when the neighboring column has no vertical constraint violation (VCV).

## Contract

- ABI: `i64_array_scalar`; symbol: `ptrdist_yacr2_maze1_dogleg`.
- Input: `[columns, tracks, column, bottom_track, top_track, vcv_flags..., occupied_cells...]`.
- `columns` and `tracks` are 2 through 16. `column` is one-based in `1..columns`; the assigned bottom and top tracks satisfy `1 <= bottom_track < top_track <= tracks`.
- The next `columns` integers are per-column VCV flags in left-to-right order. The remaining `(tracks+2)*columns` integers describe rows `0..tracks+1`, each with columns `1..columns`; 0 is free and 1 occupied. This normalized row-major profile represents the source's channel-plane logical cells.
- Source `SegmentFree` checks endpoints inclusively. The route candidates use the source's top/bottom terminal positions and track boundary rows. The port returns 1 for the first left upper dogleg, 2 for right upper, 3 for left lower, 4 for right lower, 0 when all applicable candidates are blocked, and -1 for invalid input. The selected result represents the source's route decision; drawing the returned path, updating the planes, net cleanup, VCG construction, channel expansion, and all other router phases are outside this one-call profile.
- Maximum input length is 309. Invalid dimensions, track order, flags, occupancy values, or exact framing return -1.

The workload includes hand-described open and blocked planes that exercise each `-DTODD` branch in order. The independent Python oracle uses interval scans over the logical occupancy grid rather than the source's flattened map macros.

## Provenance and rights

- Pinned repository: [`lac-dcc/Benchmarks`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38), commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`.
- Kernel: `Maze1Mech` and the `Maze1` caller in [`maze.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Ptrdist/yacr2/maze.c), especially its `TODD` left/right upper/lower branch sequence. The launcher is [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Ptrdist/yacr2/info.sh); it enables `-DTODD` and names `input2.in`.
- No explicit license or redistribution grant was found in the inspected YACR2 source files, `info.sh`, or repository-root `LICENSE`/`COPYING` paths (both absent at this commit). No license is inferred. These ports and the oracle are clean-room implementations of the bounded route decision and do not copy upstream source text, comments, or `input2.in`.

## Language ports

| Language | Source |
| --- | --- |
| C | [c/p/ptrdist_yacr2_maze1_dogleg.c](../../../c/p/ptrdist_yacr2_maze1_dogleg.c) |
| C3 | [c3/p/ptrdist_yacr2_maze1_dogleg.c3](../../../c3/p/ptrdist_yacr2_maze1_dogleg.c3) |
| C++ | [cpp/p/ptrdist_yacr2_maze1_dogleg.cpp](../../../cpp/p/ptrdist_yacr2_maze1_dogleg.cpp) |
| Elisa | [elisa/p/ptrdist_yacr2_maze1_dogleg.elisa](../../../elisa/p/ptrdist_yacr2_maze1_dogleg.elisa) |
| Nim | [nim/p/ptrdist_yacr2_maze1_dogleg.nim](../../../nim/p/ptrdist_yacr2_maze1_dogleg.nim) |
| Odin | [odin/p/ptrdist_yacr2_maze1_dogleg.odin](../../../odin/p/ptrdist_yacr2_maze1_dogleg.odin) |
| Rust | [rust/p/ptrdist_yacr2_maze1_dogleg.rs](../../../rust/p/ptrdist_yacr2_maze1_dogleg.rs) |
| V | [v/p/ptrdist_yacr2_maze1_dogleg.v](../../../v/p/ptrdist_yacr2_maze1_dogleg.v) |
| Zig | [zig/p/ptrdist_yacr2_maze1_dogleg.zig](../../../zig/p/ptrdist_yacr2_maze1_dogleg.zig) |
