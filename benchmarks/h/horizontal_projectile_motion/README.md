# Horizontal Projectile Motion

This package follows the pinned Python implementation of horizontal projectile motion from ground level. Gravity is fixed at `9.80665 m/s²`; the three source functions return horizontal distance, maximum height, and total flight time, each rounded to two decimal places.

## Contract

The `i64_array_bytes_output` input is exactly `[velocity_milli, angle_millidegrees]`. Convert each integer to its source value by dividing by `1000`: velocity is in `0..100000` (0..100 m/s), and angle is in `1000..90000` (1..90 degrees). Zero velocity is valid.

The outputs are ordered as distance in metres, maximum height in metres, and flight time in seconds. Each uses the source formula and is rounded once at the end to two decimal places with ties to even. The three binary64 values are serialized as 24 little-endian bytes (`<ddd`) and compared as a float64 vector with the workload tolerances. Invalid input returns `-1`; insufficient output capacity returns `-2`.

The formulas use the source expression order and `g = 9.80665`:

- `round(v² * sin(radians(2 * angle)) / g, 2)`
- `round(v² * sin(radians(angle))² / (2 * g), 2)`
- `round(2 * v * sin(radians(angle)) / g, 2)`

The ports round the exact binary64 formula result to the nearest hundredth with ties to even, then store that rounded value as binary64. This preserves the source rounding boundary without an extra floating-point multiply by 100.

## Workload

Cases, expected vectors, and output-capacity probes are in [`workload.json`](workload.json).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/h/horizontal_projectile_motion.c`](../../../c/h/horizontal_projectile_motion.c) |
| C3 | [`c3/h/horizontal_projectile_motion.c3`](../../../c3/h/horizontal_projectile_motion.c3) |
| C++ | [`cpp/h/horizontal_projectile_motion.cpp`](../../../cpp/h/horizontal_projectile_motion.cpp) |
| Elisa | [`elisa/h/horizontal_projectile_motion.elisa`](../../../elisa/h/horizontal_projectile_motion.elisa) |
| Nim | [`nim/h/horizontal_projectile_motion.nim`](../../../nim/h/horizontal_projectile_motion.nim) |
| Odin | [`odin/h/horizontal_projectile_motion.odin`](../../../odin/h/horizontal_projectile_motion.odin) |
| Rust | [`rust/h/horizontal_projectile_motion.rs`](../../../rust/h/horizontal_projectile_motion.rs) |
| V | [`v/h/horizontal_projectile_motion.v`](../../../v/h/horizontal_projectile_motion.v) |
| Zig | [`zig/h/horizontal_projectile_motion.zig`](../../../zig/h/horizontal_projectile_motion.zig) |

## Source

[Pinned Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/horizontal_projectile_motion.py)
