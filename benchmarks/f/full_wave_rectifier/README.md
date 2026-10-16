# full_wave_rectifier

This benchmark follows the six deterministic helpers in the pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/electronics/full_wave_rectifier.py): `max_load_current`, `dc_current`, `dc_voltage`, `max_current`, `rms_current`, and `rms_voltage`. The source wraps each answer in a `Result(name, value)` tuple; the benchmark preserves the values in that helper order and omits the names from the machine output.

## Contract

The `i64_array_bytes_output` input is exactly `[rf, rs, rl, vm, im]`, in whole ohms, volts, and amperes. The bounded domain is `rf, rs ∈ [0, 1,000,000]`, `rl ∈ [1, 1,000,000]`, and `vm, im ∈ [-1,000,000, 1,000,000]`. This is a finite integral subset of the source's floating-point domain. It keeps every operation finite and satisfies both source preconditions: resistances are nonnegative with a positive total, and load resistance is positive.

Outputs are six IEEE-754 binary64 values serialized as 48 little-endian bytes, in this order:

1. `vm / (rf + rs + rl)`
2. `2 * im * 0.318`
3. `2 * 0.318 * vm`
4. `vm / rl`
5. `im * 0.707`
6. `vm * 0.707`

Each port preserves the source operation order and binary64 constants. Invalid input returns `-1`; insufficient output capacity returns `-2`. Input validation takes precedence over output capacity, matching the byte-output ABI convention.

The workload includes a combined pinned example for `max_load_current` and `dc_current`, plus positive and negative signals, zero signals, resistance boundaries, malformed lengths and domains, signed 64-bit extremes, and the 47/48-byte output-capacity boundary. See [`workload.json`](workload.json).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/full_wave_rectifier.c`](../../../c/f/full_wave_rectifier.c) |
| C3 | [`c3/f/full_wave_rectifier.c3`](../../../c3/f/full_wave_rectifier.c3) |
| C++ | [`cpp/f/full_wave_rectifier.cpp`](../../../cpp/f/full_wave_rectifier.cpp) |
| Elisa | [`elisa/f/full_wave_rectifier.elisa`](../../../elisa/f/full_wave_rectifier.elisa) |
| Nim | [`nim/f/full_wave_rectifier.nim`](../../../nim/f/full_wave_rectifier.nim) |
| Odin | [`odin/f/full_wave_rectifier.odin`](../../../odin/f/full_wave_rectifier.odin) |
| Rust | [`rust/f/full_wave_rectifier.rs`](../../../rust/f/full_wave_rectifier.rs) |
| V | [`v/f/full_wave_rectifier.v`](../../../v/f/full_wave_rectifier.v) |
| Zig | [`zig/f/full_wave_rectifier.zig`](../../../zig/f/full_wave_rectifier.zig) |
