# Relativistic Velocity Summation

This benchmark ports the pinned Python velocity addition formula from special relativity. It combines an object's velocity relative to a moving frame with that frame's velocity relative to an observer.

## Contract

- The `i64_array_float64` ABI supplies exactly `[object_velocity_m_per_s, frame_velocity_m_per_s]` as signed 64-bit integers.
- Let `c = 299792458` m/s. Object velocity is in `[-c, c]`; frame velocity is in `[-(c-1), c-1]`. This preserves the source's asymmetric boundary: the object may equal either light-speed endpoint, while the frame must be strictly below light speed in magnitude. Superluminal values are excluded.
- Preserve the source order: `numerator = object_velocity + frame_velocity`, `denominator = 1 + object_velocity * frame_velocity / c**2`, then `numerator / denominator`.
- Malformed inputs or values outside the contract return `-1e300`. Results use relative and absolute tolerance `1e-12`.

This uses the Lorentz velocity addition formula and is distinct from classical velocity addition (`u + v`). It is also distinct from `escape_velocity` and `terminal_velocity`, which compute other physical quantities.

## Source

- [TheAlgorithms/Python `relativistic_velocity_summation.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/relativistic_velocity_summation.py)

## Workload and build

[`workload.json`](workload.json) covers the pinned examples, signed velocities, both object light-speed endpoints, and invalid bounds. Build with the `i64_array_float64` ABI and record with `benchmarks/run_i64_array_float64.py`.

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm relativistic_velocity_summation --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/r/relativistic_velocity_summation/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/r/relativistic_velocity_summation.c`](../../../c/r/relativistic_velocity_summation.c) |
| C3 | [`c3/r/relativistic_velocity_summation.c3`](../../../c3/r/relativistic_velocity_summation.c3) |
| C++ | [`cpp/r/relativistic_velocity_summation.cpp`](../../../cpp/r/relativistic_velocity_summation.cpp) |
| Elisa | [`elisa/r/relativistic_velocity_summation.elisa`](../../../elisa/r/relativistic_velocity_summation.elisa) |
| Nim | [`nim/r/relativistic_velocity_summation.nim`](../../../nim/r/relativistic_velocity_summation.nim) |
| Odin | [`odin/r/relativistic_velocity_summation.odin`](../../../odin/r/relativistic_velocity_summation.odin) |
| Rust | [`rust/r/relativistic_velocity_summation.rs`](../../../rust/r/relativistic_velocity_summation.rs) |
| V | [`v/r/relativistic_velocity_summation.v`](../../../v/r/relativistic_velocity_summation.v) |
| Zig | [`zig/r/relativistic_velocity_summation.zig`](../../../zig/r/relativistic_velocity_summation.zig) |
