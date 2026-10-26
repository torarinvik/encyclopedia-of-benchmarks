# Weighted average

Compute the weighted arithmetic mean of paired values and weights. The packed input lets the existing integer-array-to-binary64 ABI carry both arrays while keeping the source's sum-then-divide formula.

## Contract

- Input is a signed 64-bit integer array laid out as `[n, values[0], ..., values[n-1], weights[0], ..., weights[n-1]]`.
- `n` must be in `[1, 64]`, and the packed length must be exactly `1 + 2*n`. Each value and weight must be in `[-1,000,000, 1,000,000]`. Negative weights are permitted when their total is nonzero, matching the pinned source's formula.
- Compute the exact integer sums `weighted_sum = Σ(values[i] * weights[i])` and `total_weight = Σ(weights[i])`, then return `weighted_sum / total_weight` as binary64. The bounds keep both sums exact when converted to binary64 before division: the weighted sum magnitude is at most `6.4e13`, below `2^53`.
- If the packed input is invalid or the total weight is zero, return `-1e300`. The pinned Python source raises `ValueError` for empty values, mismatched value/weight lengths, and zero total weight, in that order; the benchmark maps those invalid forms to the shared sentinel.
- The algorithm uses `O(n)` time and `O(1)` auxiliary space.

## Source and related algorithms

The pinned [Python `weighted_average.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/weighted_average.py) sums the weights, sums each paired product, then divides the product sum by the weight sum. The canonical [`arithmetic_mean` benchmark](../../a/arithmetic_mean/README.md) computes an unweighted mean; weighting changes the aggregation rule and is measured separately here.

## Workload and build

[`workload.json`](workload.json) covers equal and unequal weights, fractional output, negative values and weights, and invalid packed inputs. All nine ports use the shared `i64_array_float64` ABI.

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm weighted_average --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/w/weighted_average/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/w/weighted_average.c`](../../../c/w/weighted_average.c) |
| C3 | [`c3/w/weighted_average.c3`](../../../c3/w/weighted_average.c3) |
| C++ | [`cpp/w/weighted_average.cpp`](../../../cpp/w/weighted_average.cpp) |
| Elisa | [`elisa/w/weighted_average.elisa`](../../../elisa/w/weighted_average.elisa) |
| Nim | [`nim/w/weighted_average.nim`](../../../nim/w/weighted_average.nim) |
| Odin | [`odin/w/weighted_average.odin`](../../../odin/w/weighted_average.odin) |
| Rust | [`rust/w/weighted_average.rs`](../../../rust/w/weighted_average.rs) |
| V | [`v/w/weighted_average.v`](../../../v/w/weighted_average.v) |
| Zig | [`zig/w/weighted_average.zig`](../../../zig/w/weighted_average.zig) |
