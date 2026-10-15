# Alternating harmonic series

## Contract

Input is a packed rational sequence, `[term_count, numerator_0, denominator_0, ...]`. Each term is `numerator / denominator`; denominators must be positive. The term count is 0 through 1,000, numerators are in `[-1000, 1000]`, and denominators are in `[1, 1000]`. A malformed array or out-of-range term returns `-1`.

Return `1` when every term is within an absolute tolerance of `1e-9` of the corresponding canonical finite alternating harmonic term `1, -1/2, 1/3, -1/4, ...`; otherwise return `0`. The empty sequence returns `0`. The tolerance comparison is inclusive.

The rational packed input keeps this benchmark portable across the nine integer-array ABI implementations and allows the comparison to use exact integer arithmetic. It represents finite sequences directly; it does not approximate the original Python implementation's floating-point inputs.

## Workload and verification

See [`workload.json`](workload.json) for empty, short canonical prefixes, exact rational canonical terms, nonmatching terms, and a 1,000-term canonical prefix. Build and run with the `i64_array_scalar` ABI family:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm alternating_harmonic_series --language rust --with-checker
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/a/alternating_harmonic_series/rust/build.json
```

The shared runner validates the workload with exact integer arithmetic for the inclusive `1e-9` comparison against each canonical term.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/alternating_harmonic_series.c`](../../../c/a/alternating_harmonic_series.c) |
| C3 | [`c3/a/alternating_harmonic_series.c3`](../../../c3/a/alternating_harmonic_series.c3) |
| C++ | [`cpp/a/alternating_harmonic_series.cpp`](../../../cpp/a/alternating_harmonic_series.cpp) |
| Elisa | [`elisa/a/alternating_harmonic_series.elisa`](../../../elisa/a/alternating_harmonic_series.elisa) |
| Nim | [`nim/a/alternating_harmonic_series.nim`](../../../nim/a/alternating_harmonic_series.nim) |
| Odin | [`odin/a/alternating_harmonic_series.odin`](../../../odin/a/alternating_harmonic_series.odin) |
| Rust | [`rust/a/alternating_harmonic_series.rs`](../../../rust/a/alternating_harmonic_series.rs) |
| V | [`v/a/alternating_harmonic_series.v`](../../../v/a/alternating_harmonic_series.v) |
| Zig | [`zig/a/alternating_harmonic_series.zig`](../../../zig/a/alternating_harmonic_series.zig) |

## TheAlgorithms reference

- [Python `alternating_harmonic_series.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/series/alternating_harmonic_series.py)
