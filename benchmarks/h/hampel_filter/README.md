# Hampel filter

This benchmark measures the pinned Java streaming Hampel filter with its default threshold and a fixed window size of three. Each new raw sample enters the causal window. The filter computes the window median and the median absolute deviation (MAD), then replaces the current output with the median only when

```text
abs(sample - median) > 3.0 * 1.4826 * MAD
```

The comparison is strict. A replaced sample remains in the window as its original raw value, so it can affect later medians until it ages out.

## Contract

- Pack signed 64-bit integers as `[n, samples...]`, with exactly `n + 1` values. `n` is in `0..=128`; every sample is in `[-1000, 1000]`.
- The window size is fixed at three and the threshold is fixed at the source default, `3.0`.
- Return one filtered sample per input sample, in input order, encoded as little-endian signed 64-bit integers. Empty input returns zero bytes.
- Malformed packing or out-of-domain samples return `-1`. The output workspace is 1,024 bytes. Capacity below `8*n` returns `-2`.

The benchmark domain makes every input exactly representable as binary64. During the two-sample warm-up, the even-sized median can be a half-integer, but neither point can exceed three scaled MADs. Once the window is full, its three-sample median is an input integer. Thus all emitted values are exact integers and can be encoded without rounding.

## Source

- [TheAlgorithms/Java `HampelFilter.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/streaming/HampelFilter.java), commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`, under the repository's [MIT license](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/LICENSE).
- The source delegates median computation to [`MedianFilter.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/streaming/MedianFilter.java) at the same commit.

This is a causal outlier filter that emits every sample, sometimes replacing it with the local median. It differs from a windowed-median operation, which emits the median itself for each window. See [`workload.json`](workload.json) for empty input, warm-up, window fill, replacement, post-outlier behavior, malformed input, and capacity handling.

Verify all language ports against the bounded oracle and workload with `python3 benchmarks/verify_i64_array_bytes_output.py --algorithm hampel_filter`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/h/hampel_filter.c`](../../../c/h/hampel_filter.c) |
| C3 | [`c3/h/hampel_filter.c3`](../../../c3/h/hampel_filter.c3) |
| C++ | [`cpp/h/hampel_filter.cpp`](../../../cpp/h/hampel_filter.cpp) |
| Elisa | [`elisa/h/hampel_filter.elisa`](../../../elisa/h/hampel_filter.elisa) |
| Nim | [`nim/h/hampel_filter.nim`](../../../nim/h/hampel_filter.nim) |
| Odin | [`odin/h/hampel_filter.odin`](../../../odin/h/hampel_filter.odin) |
| Rust | [`rust/h/hampel_filter.rs`](../../../rust/h/hampel_filter.rs) |
| V | [`v/h/hampel_filter.v`](../../../v/h/hampel_filter.v) |
| Zig | [`zig/h/hampel_filter.zig`](../../../zig/h/hampel_filter.zig) |

All nine implementations passed 266 oracle cases and 8 workload records per language.
