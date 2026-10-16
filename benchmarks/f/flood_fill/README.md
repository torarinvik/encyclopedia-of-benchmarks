# Flood fill

This benchmark models the bounded eight-connected region replacement in the pinned C# `FloodFill` class. The source provides both breadth-first and depth-first routines; these ports use an iterative stack and return the same completed image.

## Contract

- Input is `[width, height, start_x, start_y, new_color, target_color, pixels...]`. Width and height are 1..32. Pixels are stored x-major at `x * height + y`; colors are signed 32-bit values.
- Starting at the seed, replace every pixel equal to `target_color` that is connected through horizontal, vertical, or diagonal neighbors. If the seed is not the target color, the image is unchanged.
- `new_color` must differ from `target_color`; the pinned source's breadth-first routine would keep enqueuing unchanged target pixels otherwise. Invalid input returns `-1`; insufficient output capacity returns `-2`. Output is the entire image as little-endian signed 64-bit values, and the result is its byte length.
- The independent oracle uses a FIFO traversal. Runtime and auxiliary space are O(width × height).

[`workload.json`](workload.json) covers diagonal connectivity, border-reaching regions, a seed that does not match, a single pixel, malformed inputs, equal colors, and capacity failure.

Build and record with the `i64_array_bytes_output` ABI family:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm flood_fill --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm flood_fill
```

## Implementations

Portable ports are in `c/f/flood_fill.c`, `c3/f/flood_fill.c3`, `cpp/f/flood_fill.cpp`, `elisa/f/flood_fill.elisa`, `nim/f/flood_fill.nim`, `odin/f/flood_fill.odin`, `rust/f/flood_fill.rs`, `v/f/flood_fill.v`, and `zig/f/flood_fill.zig`.

## Pinned source

- [TheAlgorithms/C-Sharp `FloodFill.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Other/FloodFill.cs) uses eight neighbors and compares full pixel colors.
