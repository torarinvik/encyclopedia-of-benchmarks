# Value at Risk

This benchmark ports the pinned Python historical-simulation `value_at_risk` function. It sorts the returns, linearly interpolates the empirical quantile at `1 - confidence_level`, then returns the negative of that threshold.

## Contract

- The `i64_array_float64` input is packed as `[confidence_micro, return_count, returns_micro...]`. Values use 1,000,000 integer units per physical unit.
- Confidence is in `[0.000001, 0.999999]`; there must be 1 through 64 returns, each in `[-1,000, 1,000]` physical units. This bounded fixed-point domain maps to finite source inputs.
- The quantile uses the source's linear interpolation between adjacent sorted returns. The result is `-threshold`; unlike expected shortfall, it does not average the lower tail.
- The source raises for empty inputs and invalid confidence. The benchmark maps malformed, empty, or out-of-domain input to `-1e300`.
- The parser admits 65 returns so a complete one-over-bound record fits; valid inputs remain capped at 64 returns.

## Pinned source

Python [`financial/value_at_risk.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/financial/value_at_risk.py) at commit `e1a2a8b016001309a73d5fec4818c35cca139795`.

## Workload and build

[`workload.json`](workload.json) covers the pinned examples, fractional quantiles, unsorted inputs, confidence boundaries, maximum length, and malformed or invalid-domain records. The independent oracle is [`value_at_risk_oracle.py`](../../value_at_risk_oracle.py).

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm value_at_risk --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/v/value_at_risk/rust/build.json
python3 benchmarks/verify_i64_array_float64.py --algorithms value_at_risk
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/v/value_at_risk.c`](../../../c/v/value_at_risk.c) |
| C3 | [`c3/v/value_at_risk.c3`](../../../c3/v/value_at_risk.c3) |
| C++ | [`cpp/v/value_at_risk.cpp`](../../../cpp/v/value_at_risk.cpp) |
| Elisa | [`elisa/v/value_at_risk.elisa`](../../../elisa/v/value_at_risk.elisa) |
| Nim | [`nim/v/value_at_risk.nim`](../../../nim/v/value_at_risk.nim) |
| Odin | [`odin/v/value_at_risk.odin`](../../../odin/v/value_at_risk.odin) |
| Rust | [`rust/v/value_at_risk.rs`](../../../rust/v/value_at_risk.rs) |
| V | [`v/v/value_at_risk.v`](../../../v/v/value_at_risk.v) |
| Zig | [`zig/v/value_at_risk.zig`](../../../zig/v/value_at_risk.zig) |
