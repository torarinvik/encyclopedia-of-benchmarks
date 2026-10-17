# Sharpe ratio

Calculate the non-annualized Sharpe ratio for a bounded series of periodic
returns using the pinned Python `sharpe_ratio` function. The separate
`annualized_sharpe_ratio` helper is outside this package.

## Contract

- Input is a signed 64-bit array `[count, return_0_micro, ..., return_n-1_micro, risk_free_micro]`.
  Divide every return and the per-period risk-free rate by `1_000_000.0` to
  obtain the source's binary64 inputs.
- `count` is 2..64. The exact packed length is `count + 2`, so the maximum
  valid input has 66 words and the maximum parseable malformed input has 67.
- Returns are bounded to -200,000..200,000 micro-units (-0.2..0.2); the
  per-period risk-free rate is bounded to -100,000..100,000 micro-units
  (-0.1..0.1). Constant-return arrays are outside the benchmark domain so the
  scalar result remains finite. The source returns positive infinity for a
  constant series with positive excess return and `0.0` otherwise.
- Preserve the source operation order: mean = `sum(returns) / count`, excess =
  `mean - risk_free_rate`, sample variance =
  `sum((return - mean) ** 2) / (count - 1)`, standard deviation =
  `variance ** 0.5`, result = `excess / standard_deviation`. Negative ratios
  are returned without clamping.
- A null input pointer, invalid framing, count, range, or a constant-return
  series returns the finite sentinel `-1e300`. Results use absolute and
  relative tolerances of `1e-12`.

## Workload and oracle

[`workload.json`](workload.json) covers the pinned source examples, positive and
negative excess returns, two-value and maximum-length inputs, range boundaries,
constant returns, null input, and malformed input. The independent oracle is
[`benchmarks/sharpe_ratio_oracle.py`](../../sharpe_ratio_oracle.py).

## Reviewed source

[TheAlgorithms/Python `financial/sharpe_ratio.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/financial/sharpe_ratio.py)

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm sharpe_ratio --language rust
python3 benchmarks/run_i64_array_float64.py --algorithm sharpe_ratio
python3 benchmarks/verify_i64_array_float64.py --algorithm sharpe_ratio
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/sharpe_ratio.c`](../../../c/s/sharpe_ratio.c) |
| C3 | [`c3/s/sharpe_ratio.c3`](../../../c3/s/sharpe_ratio.c3) |
| C++ | [`cpp/s/sharpe_ratio.cpp`](../../../cpp/s/sharpe_ratio.cpp) |
| Elisa | [`elisa/s/sharpe_ratio.elisa`](../../../elisa/s/sharpe_ratio.elisa) |
| Nim | [`nim/s/sharpe_ratio.nim`](../../../nim/s/sharpe_ratio.nim) |
| Odin | [`odin/s/sharpe_ratio.odin`](../../../odin/s/sharpe_ratio.odin) |
| Rust | [`rust/s/sharpe_ratio.rs`](../../../rust/s/sharpe_ratio.rs) |
| V | [`v/s/sharpe_ratio.v`](../../../v/s/sharpe_ratio.v) |
| Zig | [`zig/s/sharpe_ratio.zig`](../../../zig/s/sharpe_ratio.zig) |
