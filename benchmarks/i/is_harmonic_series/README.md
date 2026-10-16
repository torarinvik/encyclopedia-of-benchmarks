# Harmonic-series predicate

This package ports the `is_harmonic_series` predicate from the pinned Python `harmonic.py` source. It tests whether the reciprocals of a nonempty sequence have exactly equal consecutive differences, using binary64 arithmetic and exact equality as the source does.

## Contract

- Input is `[count, binary64_bits_as_signed_i64...]`, with `count` from 1 through 32. Each payload integer is reinterpreted as one IEEE-754 binary64 value; this preserves the source's floating-point reciprocal and equality behavior.
- Either signed zero and malformed input map to the invalid-result sentinel `-1e300`. Other binary64 values, including infinities and NaNs, follow IEEE-754 arithmetic and the source's comparisons.
- Output is `1.0` for true and `0.0` for false. Comparisons are exact; no numeric tolerance applies.

## Workload and verification

[`workload.json`](workload.json) covers singleton and two-value sequences, exact harmonic progressions, non-progressions, negative values, signed zero, NaN, infinity, the maximum input length, and malformed shapes.

```sh
python3 benchmarks/verify_is_harmonic_series.py
```

## Pinned source

- Python [`harmonic.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/series/harmonic.py) (`is_harmonic_series`)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/i/is_harmonic_series.c`](../../../c/i/is_harmonic_series.c) |
| C3 | [`c3/i/is_harmonic_series.c3`](../../../c3/i/is_harmonic_series.c3) |
| C++ | [`cpp/i/is_harmonic_series.cpp`](../../../cpp/i/is_harmonic_series.cpp) |
| Elisa | [`elisa/i/is_harmonic_series.elisa`](../../../elisa/i/is_harmonic_series.elisa) |
| Nim | [`nim/i/is_harmonic_series.nim`](../../../nim/i/is_harmonic_series.nim) |
| Odin | [`odin/i/is_harmonic_series.odin`](../../../odin/i/is_harmonic_series.odin) |
| Rust | [`rust/i/is_harmonic_series.rs`](../../../rust/i/is_harmonic_series.rs) |
| V | [`v/i/is_harmonic_series.v`](../../../v/i/is_harmonic_series.v) |
| Zig | [`zig/i/is_harmonic_series.zig`](../../../zig/i/is_harmonic_series.zig) |
