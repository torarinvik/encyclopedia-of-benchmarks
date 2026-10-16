# Expected Shortfall

This benchmark ports the pinned Python historical-simulation `expected_shortfall` function. It sorts the returns, linearly interpolates the empirical quantile at `1 - confidence_level`, selects every observed return at or below that threshold, and returns the negative mean of that tail.

## Contract

- The `i64_array_float64` input is packed as `[confidence_micro, return_count, returns_micro...]`. Values use 1,000,000 integer units per physical unit.
- Confidence is in `[0.000001, 0.999999]`; there must be 1 through 64 returns, each in `[-1,000, 1,000]` physical units. This bounded fixed-point domain maps to finite source inputs.
- The quantile uses the source's linear interpolation between adjacent sorted returns. The tail includes values equal to the threshold. The result is `-sum(tail) / len(tail)`, so losses produce a positive result and gains can produce a negative result.
- The source raises for empty inputs and invalid confidence. The benchmark maps malformed, empty, or out-of-domain input to `-1e300`.
- The parser admits 65 returns so a complete one-over-bound record fits; valid inputs remain capped at 64 returns.

## Pinned source

Python [`financial/expected_shortfall.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/financial/expected_shortfall.py) at commit `e1a2a8b016001309a73d5fec4818c35cca139795`.

## Workload and build

[`workload.json`](workload.json) covers the two source examples, quantile ties, unsorted inputs, confidence boundaries, maximum length, and malformed or invalid-domain records. The independent oracle is [`expected_shortfall_oracle.py`](../../expected_shortfall_oracle.py).

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm expected_shortfall --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/e/expected_shortfall/rust/build.json
python3 benchmarks/verify_i64_array_float64.py --algorithms expected_shortfall
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/e/expected_shortfall.c`](../../../c/e/expected_shortfall.c) |
| C3 | [`c3/e/expected_shortfall.c3`](../../../c3/e/expected_shortfall.c3) |
| C++ | [`cpp/e/expected_shortfall.cpp`](../../../cpp/e/expected_shortfall.cpp) |
| Elisa | [`elisa/e/expected_shortfall.elisa`](../../../elisa/e/expected_shortfall.elisa) |
| Nim | [`nim/e/expected_shortfall.nim`](../../../nim/e/expected_shortfall.nim) |
| Odin | [`odin/e/expected_shortfall.odin`](../../../odin/e/expected_shortfall.odin) |
| Rust | [`rust/e/expected_shortfall.rs`](../../../rust/e/expected_shortfall.rs) |
| V | [`v/e/expected_shortfall.v`](../../../v/e/expected_shortfall.v) |
| Zig | [`zig/e/expected_shortfall.zig`](../../../zig/e/expected_shortfall.zig) |
