# Java t-digest quantile and CDF

This benchmark follows the pinned Java `TDigest` implementation. Input is `[compression, sample_count, samples..., quantile_count, probabilities..., cdf_count, cdf_values...]`. Compression is an integer from 10 through 20; the workload accepts 1–32 integer samples in `[-8,8]`, 1–4 quantile probabilities in quarter steps from 0 to 1, and 1–4 CDF values in `[-8,8]`.

The adapter constructs a fresh digest, adds every sample with unit weight in input order, then queries quantiles followed by CDF values. The digest's query methods flush the pending buffer before answering. With at most 32 samples and a minimum compression of 10, all insertions fit within the source's buffer before that flush. Output is `[quantile_count, quantile results..., cdf_count, CDF results...]`.

The source keeps exact min/max values, returns the sole centroid mean for every quantile when there is one centroid, and interpolates between centroid-center knots otherwise. CDF queries below/above the observed range return 0/1; for a constant stream and an in-range query it returns 0.5. Centroid merging uses the source asin scale function, ascending mean order, weighted-mean update, and capacity fallback. Invalid framing, compression, sample, or query values return `-1`; null output or insufficient capacity returns `-2` without writes. Float comparisons use absolute and relative tolerance `1e-10`.

See the [workload](workload.json), [oracle](../../tdigest_oracle.py), and pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/streaming/TDigest.java).

## Ports

- [C](../../../c/t/tdigest.c)
- [C++](../../../cpp/t/tdigest.cpp)
- [C3](../../../c3/t/tdigest.c3)
- [Rust](../../../rust/t/tdigest.rs)
- [Elisa](../../../elisa/t/tdigest.elisa)
- [Nim](../../../nim/t/tdigest.nim)
- [Odin](../../../odin/t/tdigest.odin)
- [V](../../../v/t/tdigest.v)
- [Zig](../../../zig/t/tdigest.zig)
