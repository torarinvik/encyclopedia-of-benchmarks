# Exponential distribution statistics

This benchmark ports the three statistics from the pinned C++
[`exponential_dist.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/probability/exponential_dist.cpp):
expected value, variance, and standard deviation for an exponential rate
parameter `lambda`. The source places these functions inside a namespace named
`geometric_dist`; the benchmark keeps the source behavior and gives the adapter
one stable export symbol.

## Contract

- Input uses `i64_array_float64`, packed as `[operation, lambda_micro]` with
  1,000,000 integer units per rate unit. The valid rate range is
  `[0.000001, 1,000]`.
- Operation `0` returns expected value `1 / lambda`; operation `1` returns
  variance `1 / lambda²`; operation `2` returns standard deviation
  `1 / lambda`.
- The source throws `invalid_argument` when `lambda <= 0`. Invalid selectors,
  nonpositive or out-of-range rates, malformed input, and null input return
  `-1e300` in this ABI adaptation.
- The parser admits three values to cover a one-extra-value malformed record;
  valid input has exactly two. The bounded rates keep every valid result finite.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/e/exponential_dist.c`](../../../c/e/exponential_dist.c) |
| C3 | [`c3/e/exponential_dist.c3`](../../../c3/e/exponential_dist.c3) |
| C++ | [`cpp/e/exponential_dist.cpp`](../../../cpp/e/exponential_dist.cpp) |
| Elisa | [`elisa/e/exponential_dist.elisa`](../../../elisa/e/exponential_dist.elisa) |
| Nim | [`nim/e/exponential_dist.nim`](../../../nim/e/exponential_dist.nim) |
| Odin | [`odin/e/exponential_dist.odin`](../../../odin/e/exponential_dist.odin) |
| Rust | [`rust/e/exponential_dist.rs`](../../../rust/e/exponential_dist.rs) |
| V | [`v/e/exponential_dist.v`](../../../v/e/exponential_dist.v) |
| Zig | [`zig/e/exponential_dist.zig`](../../../zig/e/exponential_dist.zig) |

The workload is [`workload.json`](workload.json), and the oracle is
[`exponential_dist_oracle.py`](../../exponential_dist_oracle.py).
