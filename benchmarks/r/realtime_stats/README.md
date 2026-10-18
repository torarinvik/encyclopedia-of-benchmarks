# Realtime Statistics

This benchmark compares the two streaming statistics methods in the pinned C
source and the Welford method in the pinned C++ source. Each benchmark call
replays one independent sample stream from the method's initial state and
returns one selected statistic.

## Contract

- The `i64_array_float64` ABI receives
  `[variant, statistic, count, q0, ..., q(count-1)]` and returns one binary64
  value. The input length must be exactly `3 + count`; the parser accepts at
  most 36 words so it can detect one trailing word after a maximum-size stream.
- `variant` selects a source method:
  - `0`: C `stats_computer1`, anchored at the first sample, using float32
    state and arithmetic. Its variance is the sample variance
    `(Ex2 - Ex*Ex/n) / (n - 1)`.
  - `1`: C `stats_computer2`, Welford updates with float32 state and
    arithmetic. Its variance is the population variance `M / n`.
  - `2`: C++ `stats_computer2<float>`, Welford updates with each input first
    represented as float32 and with double-precision state and arithmetic. Its
    variance is the population variance `M / n`.
- `statistic` selects `0` for mean, `1` for variance, or `2` for standard
  deviation. Standard deviation is the square root of the selected method's
  variance, using float32 rounding for variants 0 and 1 and binary64 for
  variant 2.
- `count` must be from 2 through 32. Each sample word `q` must be from -64
  through 64 and represents the exact binary32 sample `q / 16`, bounded to
  [-4, 4]. These dyadic inputs are exactly representable as float32.
- A null input pointer or invalid framing, selector, count, or sample returns
  `-1e300`. Compare results using absolute and relative tolerances of `1e-6`.
- Each port re-expresses the selected update equations with local per-call
  state, initializes that state to the source's initial values, and replays the
  complete input sequence. C variant 0 starts with `n=0`, `Ex=0`, and `Ex2=0`
  and sets `K` from its first sample; C variant 1 starts with `n=0`, `mu=0`,
  and `M=0`; C++ variant 2 starts with `n=0`, `mu=0`, and `M=0`. This keeps
  repeated benchmark calls deterministic while preserving the update order
  within one stream. The C functions use process-static state across calls;
  the benchmark does not carry that state between ABI calls.

## Source semantics

The C implementation is pinned at commit
[`e5dad3fa8def3726ec850ca66a7f51521f8ad393`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/numerical_methods/realtime_stats.c).
Its anchored-mean method uses the sample-variance denominator `n - 1`; its
Welford method uses `M / n`. The benchmark requires at least two samples, so
the anchored-mean variance is defined.

The C++ implementation is pinned at commit
[`fdcc29b0ac2848e9d1a8d926e171cc5b39f97759`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/realtime_stats.cpp).
The benchmark follows the `stats_computer2<float>` instance used by its test
path: samples are float32, then Welford state and intermediate values are
binary64. C++ method 1 is excluded because its `Ex` and `Ex2` fields are
uninitialized, so its results are not deterministic. The additional C++
repository source is pinned at commit
[`0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/realtime_stats.cpp).
It contains the same implementation and adds no distinct method.

## Workload and oracle

[`workload.json`](workload.json) includes each supported method and statistic,
constant and alternating streams, the maximum sample count, and malformed
selectors, counts, and sample values. The independent source-order oracle is
[`realtime_stats_oracle.py`](../../realtime_stats_oracle.py).

Build and record with the `i64_array_float64` family:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm realtime_stats --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/r/realtime_stats/rust/build.json
python3 benchmarks/verify_i64_array_float64.py --algorithm realtime_stats
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/realtime_stats.c`](../../../c/r/realtime_stats.c) |
| C3 | [`c3/r/realtime_stats.c3`](../../../c3/r/realtime_stats.c3) |
| C++ | [`cpp/r/realtime_stats.cpp`](../../../cpp/r/realtime_stats.cpp) |
| Elisa | [`elisa/r/realtime_stats.elisa`](../../../elisa/r/realtime_stats.elisa) |
| Nim | [`nim/r/realtime_stats.nim`](../../../nim/r/realtime_stats.nim) |
| Odin | [`odin/r/realtime_stats.odin`](../../../odin/r/realtime_stats.odin) |
| Rust | [`rust/r/realtime_stats.rs`](../../../rust/r/realtime_stats.rs) |
| V | [`v/r/realtime_stats.v`](../../../v/r/realtime_stats.v) |
| Zig | [`zig/r/realtime_stats.zig`](../../../zig/r/realtime_stats.zig) |
