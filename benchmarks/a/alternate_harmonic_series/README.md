# Alternate harmonic series

## Contract

Input is a packed rational sequence, `[term_count, numerator_0, denominator_0, ...]`. Each term is `numerator / denominator`; denominators must be positive. The term count is 1 through 1,000, numerators are nonzero and in `[-1000, 1000]`, and denominators are in `[1, 1000]`. A malformed array or out-of-range term returns `-1`.

Return `1` when the terms alternate in sign and the magnitudes of their reciprocals form an arithmetic progression; otherwise return `0`. A singleton satisfies the predicate. For two terms, only the alternating-sign condition applies. Reciprocal magnitudes are `denominator / abs(numerator)`, compared exactly as rational numbers.

The rational packed input keeps this benchmark portable across the nine integer-array ABI implementations while preserving exact comparisons. It represents finite sequences directly; it does not approximate the original Python implementation's floating-point inputs.

## Workload and verification

See [`workload.json`](workload.json) for singleton, canonical-prefix, scaled-fraction, two-term, sign, and progression cases, including a 1,000-term canonical prefix. Build and run with the `i64_array_scalar` ABI family:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm alternate_harmonic_series --language rust --with-checker
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/a/alternate_harmonic_series/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/alternate_harmonic_series.c`](../../../c/a/alternate_harmonic_series.c) |
| C3 | [`c3/a/alternate_harmonic_series.c3`](../../../c3/a/alternate_harmonic_series.c3) |
| C++ | [`cpp/a/alternate_harmonic_series.cpp`](../../../cpp/a/alternate_harmonic_series.cpp) |
| Elisa | [`elisa/a/alternate_harmonic_series.elisa`](../../../elisa/a/alternate_harmonic_series.elisa) |
| Nim | [`nim/a/alternate_harmonic_series.nim`](../../../nim/a/alternate_harmonic_series.nim) |
| Odin | [`odin/a/alternate_harmonic_series.odin`](../../../odin/a/alternate_harmonic_series.odin) |
| Rust | [`rust/a/alternate_harmonic_series.rs`](../../../rust/a/alternate_harmonic_series.rs) |
| V | [`v/a/alternate_harmonic_series.v`](../../../v/a/alternate_harmonic_series.v) |
| Zig | [`zig/a/alternate_harmonic_series.zig`](../../../zig/a/alternate_harmonic_series.zig) |

## TheAlgorithms reference

- [Python `alternate_harmonic_series.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/series/alternate_harmonic_series.py)
