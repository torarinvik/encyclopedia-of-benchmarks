# Binomial distribution probability

Compute the probability of exactly `x` successes in `n` independent Bernoulli trials.

## Contract

- The `float64_triple` ABI accepts `[n, p, x]` as three binary64 inputs.
- `n` and `x` are integral, `1 <= x <= n <= 16`, and `p` is one of `0.25`, `0.5`, or `0.75`.
- The result follows the pinned C++ implementation's expression: `nCr(n, x) * p^x * (1-p)^(n-x)`. Its `nCr` recurrence starts with numerator `n` and denominator `x`, then multiplies the remaining factors.
- The domain omits `x = 0`, where the source initializes its denominator to zero. Exact dyadic probabilities and the small trial bound keep every workload result exactly representable as binary64.
- The workload tolerance is `1e-12` to match the three-input float64 runner.

## Source semantics

Both pinned C++ snapshots contain the same functions for expectation, variance, standard deviation, `nCr`, exact-success probability, and inclusive range probability. This package benchmarks the exact-success function (`binomial_x_successes`) with a shared three-scalar ABI. The `nCr` and PMF operation order is retained; probability endpoints and range accumulation are outside this bounded contract.

## Workload and reproduction

[`workload.json`](workload.json) covers the smallest trial count, symmetric and asymmetric counts, each probability, boundary successes `x = 1` and `x = n`, and the maximum trial count.

```sh
python3 benchmarks/build_abi.py --family float64_triple --algorithm binomial_dist --language rust
python3 benchmarks/run_float64_triple.py --build-manifest build/float64_triple/b/binomial_dist/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/binomial_dist.c`](../../../c/b/binomial_dist.c) |
| C3 | [`c3/b/binomial_dist.c3`](../../../c3/b/binomial_dist.c3) |
| C++ | [`cpp/b/binomial_dist.cpp`](../../../cpp/b/binomial_dist.cpp) |
| Elisa | [`elisa/b/binomial_dist.elisa`](../../../elisa/b/binomial_dist.elisa) |
| Nim | [`nim/b/binomial_dist.nim`](../../../nim/b/binomial_dist.nim) |
| Odin | [`odin/b/binomial_dist.odin`](../../../odin/b/binomial_dist.odin) |
| Rust | [`rust/b/binomial_dist.rs`](../../../rust/b/binomial_dist.rs) |
| V | [`v/b/binomial_dist.v`](../../../v/b/binomial_dist.v) |
| Zig | [`zig/b/binomial_dist.zig`](../../../zig/b/binomial_dist.zig) |

## Pinned sources

- Python [`binomial_distribution.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/binomial_distribution.py) computes the exact-success probability and maps on `1 <= x <= n <= 16` with `p` in `{0.25, 0.5, 0.75}`, where the dyadic probability inputs align with this contract.
- [C-Plus-Plus `binomial_dist.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/probability/binomial_dist.cpp)
- [C-Plus-Plus-1 `binomial_dist.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/probability/binomial_dist.cpp)
