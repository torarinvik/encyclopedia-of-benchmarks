# Midpoint Euler

Apply the midpoint Euler method to the pinned harmonic oscillator system `u' = v`, `v' = -u` for a fixed number of steps.

## Contract

- ABI: signed i64 array to byte output. Input is `[steps, dt_quarters, u0, v0]`.
- `1 <= steps <= 8`, `1 <= dt_quarters <= 4`, and `-10 <= u0, v0 <= 10`. The step is `h = dt_quarters / 4`.
- Each step follows the source operation order: `mid_u = u + (h/2)*v`; `mid_v = v - (h/2)*u`; `next_u = u + h*mid_v`; `next_v = v - h*mid_u`.
- The output is the IEEE-754 binary64 bit pattern of `u`, followed by `v`, each encoded as 8 little-endian bytes. The result is always 16 bytes.
- Invalid shape or values return `-1`. Insufficient output capacity returns `-2` without writing.

The eight-step limit keeps every midpoint and state value exactly representable in binary64 for this bounded dyadic domain. With `h` in `{1/4, 1/2, 3/4, 1}`, the state update has denominator at most `2^5` per step; after eight steps the denominator is at most `2^40`. The initial norm is at most `sqrt(200)` and each step grows it by at most `sqrt(1 + 1/4)`, so state magnitudes remain below 35. Midpoint intermediates also remain within binary64's 53-bit precision. This permits exact byte-for-byte outputs without floating tolerance.

## Source and workload

This package follows the fixed two-variable midpoint update in [TheAlgorithms/C `ode_midpoint_euler.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/numerical_methods/ode_midpoint_euler.c) and [TheAlgorithms/C-Plus-Plus `ode_midpoint_euler.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/numerical_methods/ode_midpoint_euler.cpp). The C-Plus-Plus-1 source at `0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680` is byte-identical. The source's interactive step-size input, time measurement, and CSV output are outside the numerical step contract; its do/while driver is represented by the explicit bounded step count.

The workload covers each quarter-step value, one- and multi-step updates, boundary initial values, the maximum step count, malformed inputs, and short/exact output capacities. The oracle mirrors the binary64 midpoint operation sequence.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/o/ode_midpoint_euler.c`](../../../c/o/ode_midpoint_euler.c) |
| C3 | [`c3/o/ode_midpoint_euler.c3`](../../../c3/o/ode_midpoint_euler.c3) |
| C++ | [`cpp/o/ode_midpoint_euler.cpp`](../../../cpp/o/ode_midpoint_euler.cpp) |
| Elisa | [`elisa/o/ode_midpoint_euler.elisa`](../../../elisa/o/ode_midpoint_euler.elisa) |
| Nim | [`nim/o/ode_midpoint_euler.nim`](../../../nim/o/ode_midpoint_euler.nim) |
| Odin | [`odin/o/ode_midpoint_euler.odin`](../../../odin/o/ode_midpoint_euler.odin) |
| Rust | [`rust/o/ode_midpoint_euler.rs`](../../../rust/o/ode_midpoint_euler.rs) |
| V | [`v/o/ode_midpoint_euler.v`](../../../v/o/ode_midpoint_euler.v) |
| Zig | [`zig/o/ode_midpoint_euler.zig`](../../../zig/o/ode_midpoint_euler.zig) |
