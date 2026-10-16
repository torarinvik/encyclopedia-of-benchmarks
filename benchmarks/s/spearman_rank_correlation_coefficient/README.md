# Spearman Rank Correlation Coefficient

This benchmark follows the pinned Python implementation's average-rank assignment, rank-difference formula, and one-decimal rounding. It is rank based and differs from the value-space `correlation` and Pearson benchmarks.

## Contract

- The `i64_array_float64` ABI packs `[n, x[0], ..., x[n-1], y[0], ..., y[n-1]]` as signed 64-bit integers. Require `2 <= n <= 3`, exact length `1 + 2*n`, and samples in `[-1000, 1000]`. The source accepts general float sequences and does not check equal lengths; this benchmark uses equal-length integer samples.
- Each array is sorted by value and equal values receive their average 1-based rank. Then compute `d_squared = sum((rank_x[i] - rank_y[i])**2)`, `rho = 1 - 6*d_squared/(n*(n**2 - 1))`, and round `rho` to one decimal using ties-to-even, matching Python `round(rho, 1)` over this bounded domain.
- The n<=3 bound makes every attainable rank difference a multiple of 0.5, so `d_squared` lies on quarter increments and the source `rho` lies on sixteenth increments. Any one-decimal midpoint on this grid is an exact binary fraction, so ties-to-even is portable. This bounded set retains tied ranks and positive/negative rounding cases.
- Malformed inputs or values outside the contract return `-1e300`.

## Source

- [TheAlgorithms/Python `spearman_rank_correlation_coefficient.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/spearman_rank_correlation_coefficient.py)

The source documents arrays shorter than two as an error; the benchmark maps malformed ABI inputs to `-1e300`. Its `zip` would truncate unequal-length arrays, but the packed contract requires equal lengths.

## Workload and build

[`workload.json`](workload.json) includes ties, constant arrays, positive and negative associations, and the source's one-decimal output. Build with the `i64_array_float64` ABI and record with `benchmarks/run_i64_array_float64.py`.

The shared float64 runner computes average ranks with exact rational values, applies the pinned formula, and uses Python's one-decimal ties-to-even rounding.

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm spearman_rank_correlation_coefficient --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/s/spearman_rank_correlation_coefficient/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/s/spearman_rank_correlation_coefficient.c`](../../../c/s/spearman_rank_correlation_coefficient.c) |
| C3 | [`c3/s/spearman_rank_correlation_coefficient.c3`](../../../c3/s/spearman_rank_correlation_coefficient.c3) |
| C++ | [`cpp/s/spearman_rank_correlation_coefficient.cpp`](../../../cpp/s/spearman_rank_correlation_coefficient.cpp) |
| Elisa | [`elisa/s/spearman_rank_correlation_coefficient.elisa`](../../../elisa/s/spearman_rank_correlation_coefficient.elisa) |
| Nim | [`nim/s/spearman_rank_correlation_coefficient.nim`](../../../nim/s/spearman_rank_correlation_coefficient.nim) |
| Odin | [`odin/s/spearman_rank_correlation_coefficient.odin`](../../../odin/s/spearman_rank_correlation_coefficient.odin) |
| Rust | [`rust/s/spearman_rank_correlation_coefficient.rs`](../../../rust/s/spearman_rank_correlation_coefficient.rs) |
| V | [`v/s/spearman_rank_correlation_coefficient.v`](../../../v/s/spearman_rank_correlation_coefficient.v) |
| Zig | [`zig/s/spearman_rank_correlation_coefficient.zig`](../../../zig/s/spearman_rank_correlation_coefficient.zig) |
