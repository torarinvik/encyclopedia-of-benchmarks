# Half-wave rectifier calculations

The pinned Python module contains six deterministic formulas and returns a named result tuple for each. The benchmark selects one formula with an operation code and returns its numeric value, avoiding Python tuple/string formatting while retaining the arithmetic and validation rules.

## Contract

The `i64_array_float64` ABI takes `[operation, arg1, arg2, arg3, arg4]`, with integer arguments bounded to ±1,000,000. Selectors 0–5 map to `max_load_current(rf,rs,rl,vm)`, `dc_current(im)`, `dc_voltage(vm)`, `max_current(vm,rl)`, `rms_current(im)`, and `rms_voltage(vm)`. The corresponding formulas are `vm/(rf+rs+rl)`, `im*0.318`, `vm*0.318`, `vm/rl`, `im/2`, and `vm/2`. Unused operands must be zero. The three resistances for operation 0 must be nonnegative and not all zero; operation 3 requires positive load resistance. Invalid selectors, arity, bounds, or constraints return `-1e300`.

The benchmark preserves the source's `0.318` approximation and sign behavior for voltage/current values. Each calculation takes O(1) time and space.

[`workload.json`](workload.json) covers every formula, zero/negative signals, resistance errors, unused arguments, and invalid selectors/lengths.

## Pinned source

- [Python `half_wave_rectifier.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/electronics/half_wave_rectifier.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/h/half_wave_rectifier.c`](../../../c/h/half_wave_rectifier.c) |
| C3 | [`c3/h/half_wave_rectifier.c3`](../../../c3/h/half_wave_rectifier.c3) |
| C++ | [`cpp/h/half_wave_rectifier.cpp`](../../../cpp/h/half_wave_rectifier.cpp) |
| Elisa | [`elisa/h/half_wave_rectifier.elisa`](../../../elisa/h/half_wave_rectifier.elisa) |
| Nim | [`nim/h/half_wave_rectifier.nim`](../../../nim/h/half_wave_rectifier.nim) |
| Odin | [`odin/h/half_wave_rectifier.odin`](../../../odin/h/half_wave_rectifier.odin) |
| Rust | [`rust/h/half_wave_rectifier.rs`](../../../rust/h/half_wave_rectifier.rs) |
| V | [`v/h/half_wave_rectifier.v`](../../../v/h/half_wave_rectifier.v) |
| Zig | [`zig/h/half_wave_rectifier.zig`](../../../zig/h/half_wave_rectifier.zig) |
