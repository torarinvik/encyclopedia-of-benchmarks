# Geometric distribution

Benchmark the deterministic statistics and probability functions for the source's geometric distribution, which counts trials until the first success.

## Contract

- The `i64_array_float64` ABI accepts integer selectors; each operation returns the pinned source's binary32 result widened to binary64.
- Success probability selectors are `0=0.25`, `1=0.5`, and `2=0.75`.
- Operation `0` is expected value and accepts `[0, p]`; `1` is variance and accepts `[1, p]`; `2` is standard deviation and accepts `[2, p]`.
- Operation `3` is probability density and accepts `[3, p, k]` for `1 <= k <= 16`; operation `4` is cumulative distribution and accepts `[4, p, k]` for `0 <= k <= 16`.
- Operation `5` is inverse cumulative distribution and accepts `[5, p, cdf]`, where `cdf` uses the same three probability selectors. Operation `6` is the inclusive range probability and accepts `[6, p, min_tries, max_tries]` with `1 <= min_tries <= max_tries <= 16`.
- Malformed inputs return `-1e300`. The deterministic selector excludes the source's random sampling helper; range inputs also stay below the source's `uint32_t` maximum-bound sentinel.
- Results follow binary32 operation rounding before widening. Output tolerances are absolute `1e-12` and relative `3e-6` to allow normal binary32 math-library variation.

## Source semantics

Both pinned C++ snapshots agree. The distribution is supported on positive trial counts: `pdf(k) = (1-p)^(k-1) * p`, `cdf(k) = 1 - (1-p)^k`, and `inverse_cdf(cdf) = log(1-cdf)/log(1-p)`. Expectation, variance, and standard deviation use `1/p`, `(1-p)/(p*p)`, and the square root of variance. Inclusive range probability subtracts `cdf(min-1)` from `cdf(max)`. The contract keeps the source's float32 arithmetic and operation order.

## Workload and reproduction

[`workload.json`](workload.json) includes each deterministic operation, all probability selectors, lower and upper trial bounds, valid range probabilities, malformed selectors, and invalid trial ranges.

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm geometric_dist --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/g/geometric_dist/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/g/geometric_dist.c`](../../../c/g/geometric_dist.c) |
| C3 | [`c3/g/geometric_dist.c3`](../../../c3/g/geometric_dist.c3) |
| C++ | [`cpp/g/geometric_dist.cpp`](../../../cpp/g/geometric_dist.cpp) |
| Elisa | [`elisa/g/geometric_dist.elisa`](../../../elisa/g/geometric_dist.elisa) |
| Nim | [`nim/g/geometric_dist.nim`](../../../nim/g/geometric_dist.nim) |
| Odin | [`odin/g/geometric_dist.odin`](../../../odin/g/geometric_dist.odin) |
| Rust | [`rust/g/geometric_dist.rs`](../../../rust/g/geometric_dist.rs) |
| V | [`v/g/geometric_dist.v`](../../../v/g/geometric_dist.v) |
| Zig | [`zig/g/geometric_dist.zig`](../../../zig/g/geometric_dist.zig) |

## Pinned sources

- [C-Plus-Plus `geometric_dist.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/probability/geometric_dist.cpp)
- [C-Plus-Plus-1 `geometric_dist.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/probability/geometric_dist.cpp)
