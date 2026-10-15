# ADWIN change detection

## Contract

The pinned Java implementation maintains an exponential histogram with at most five buckets at each power-of-two size. After each sample it updates the running total and variance, compresses overflowing rows, and tests admissible old/recent window cuts with a variance-sensitive confidence bound. For subwindow sizes `n0` and `n1`, minimum subwindow size `5`, whole-window variance `v`, and confidence `delta`, it computes `m = 1/(n0 - 5 + 1) + 1/(n1 - 5 + 1)`, `d = ln(2 * ln(width) / delta)`, and `epsilon = sqrt(2 * m * v * d) + (2/3) * d * m`; it cuts when the absolute difference between the subwindow means exceeds `epsilon`. It drops the oldest bucket after a significant cut and repeats until no remaining cut is significant. The reported cut flag is true if one or more buckets were dropped for that sample.

The input is `[sample_count, delta_scaled, then sample_count fixed-point samples]`. `delta` and samples are encoded at scale 1,000,000,000. The count is 1 through 256, `delta` is 1e-9 through 0.1, and each sample is in [-1, 1]. Invalid input returns `-1`.

The output contains two signed 64-bit little-endian values per accepted sample: the 0/1 cut flag and the window width after detection. The function returns the number of output words (`2 * sample_count`); an insufficient output buffer returns `-2`. Implementations preserve the source's bucket merge and cut order. They use binary64 arithmetic, a shared range-reduced logarithm series, and an 80-step Newton square root so the confidence-bound calculation does not depend on architecture-specific instructions or platform `log`/`sqrt` behavior.

## Workload and ABI

[`workload.json`](workload.json) covers a stationary signal, an abrupt mean shift, a stationary alternating signal, multiple regimes, and the maximum bounded stream length.

Build with:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm adwin --language rust --with-checker
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/a/adwin/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/adwin.c`](../../../c/a/adwin.c) |
| C3 | [`c3/a/adwin.c3`](../../../c3/a/adwin.c3) |
| C++ | [`cpp/a/adwin.cpp`](../../../cpp/a/adwin.cpp) |
| Elisa | [`elisa/a/adwin.elisa`](../../../elisa/a/adwin.elisa) |
| Nim | [`nim/a/adwin.nim`](../../../nim/a/adwin.nim) |
| Odin | [`odin/a/adwin.odin`](../../../odin/a/adwin.odin) |
| Rust | [`rust/a/adwin.rs`](../../../rust/a/adwin.rs) |
| V | [`v/a/adwin.v`](../../../v/a/adwin.v) |
| Zig | [`zig/a/adwin.zig`](../../../zig/a/adwin.zig) |

## Reviewed source

- [Java `Adwin.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/streaming/Adwin.java)
