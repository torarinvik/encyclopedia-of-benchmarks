# Weddle's rule

This benchmark preserves the pinned Python source's composite Weddle quadrature. The source creates `6 * acc + 1` evenly spaced samples, applies its periodic interior weights, and returns `0.3 * h` times the weighted sum.

## Contract

The `i64_array_float64` input is `[panel_count, step_nanounits, y0_micro, ..., y(6*panel_count)_micro]`. `panel_count` is an integer from 1 through 64. The sample count must be exactly `6 * panel_count + 1`, so the packed array length must be `6 * panel_count + 3`. `step_nanounits` represents the signed step size divided by 1,000,000,000 and is bounded to `[-1,000,000,000, 1,000,000,000]`. Each `y` is a sampled function value in millionths, bounded to `[-1,000,000, 1,000,000]`.

The interior weight at global sample index `i` is 5 when `i mod 6` is 1 or 5, 1 when it is 2 or 4, 6 when it is 3, and 2 at each interior panel boundary (`i mod 6 = 0`). The endpoints each have weight 1. The binary64 result is `0.3 * (step_nanounits / 1e9) * (weighted_sum_micro / 1e6)`. Negative step sizes preserve the source's oriented interval behavior. Invalid lengths, bounds, or panel counts return `-1e300`.

The source accepts an arbitrary callable and uses NumPy to create its sample table. This benchmark supplies that table directly at fixed-point precision, keeping the quadrature kernel deterministic across the nine ports. Each port fuses the source's weighted-value list and subsequent sum into a left-to-right accumulation; the weights and endpoint addition order are preserved.

## Pinned source

The source is [`maths/weddles_rule.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/weddles_rule.py) at commit `e1a2a8b016001309a73d5fec4818c35cca139795`. `compute_table` creates the samples, `apply_weights` defines the modulo-six weights, and `compute_solution` performs the final scaled sum.

[`workload.json`](workload.json) includes one- and multi-panel tables, a maximum-size table, positive, negative, and zero steps, weight-boundary samples, and malformed inputs.

## Build and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm weddles_rule --language rust --with-checker
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/w/weddles_rule/rust/build.json
python3 benchmarks/verify_i64_array_float64.py --algorithm weddles_rule
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/w/weddles_rule.c`](../../../c/w/weddles_rule.c) |
| C3 | [`c3/w/weddles_rule.c3`](../../../c3/w/weddles_rule.c3) |
| C++ | [`cpp/w/weddles_rule.cpp`](../../../cpp/w/weddles_rule.cpp) |
| Elisa | [`elisa/w/weddles_rule.elisa`](../../../elisa/w/weddles_rule.elisa) |
| Nim | [`nim/w/weddles_rule.nim`](../../../nim/w/weddles_rule.nim) |
| Odin | [`odin/w/weddles_rule.odin`](../../../odin/w/weddles_rule.odin) |
| Rust | [`rust/w/weddles_rule.rs`](../../../rust/w/weddles_rule.rs) |
| V | [`v/w/weddles_rule.v`](../../../v/w/weddles_rule.v) |
| Zig | [`zig/w/weddles_rule.zig`](../../../zig/w/weddles_rule.zig) |
