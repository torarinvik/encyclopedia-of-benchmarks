# Streaming median filter

This benchmark ports the pinned Java streaming filter. It reports the median of the current sample and the preceding samples still inside a causal trailing window.

## Contract

- ABI: `float64_slice_io`. Input is `[window_size, sample_count, sample_0, ..., sample_(n-1)]`, with exact length `2 + sample_count`.
- `window_size` is an exactly integral binary64 value in `[1, 16]`. `sample_count` is exactly integral and in `[0, 64]`. Samples are finite binary64 values in `[-1,000,000, 1,000,000]`. The maximum input length is 66 values.
- Each output is the median of the suffix ending at that sample, of length at most `window_size`. Before the window fills, use the available partial window. Keep duplicate samples as separate values. For an even-sized window, return `0.5 * (lower_middle + upper_middle)` in that operation order.
- The ABI adapter constructs a fresh filter for each invocation; the Java `filter` method itself continues from the instance's current state. The output contains one value per input sample and success returns that count; a zero-sample input is valid and returns an empty output with result 0. The maximum output workspace is 64 values.
- Invalid shape, header, or sample values return `-1`. For valid input, a null output pointer or insufficient capacity returns `-2` without writing output. Output comparisons use zero absolute and relative tolerance.

The similarly named Python source is an image-processing filter and is not part of this streaming contract.

## Workload and oracle

[`workload.json`](workload.json) covers causal eviction, partial warmup, even-sized medians, duplicate values, the maximum window and sample counts, empty signals, and invalid headers and sample bounds. Its ABI probes include short and null output buffers plus nonfinite samples. The independent [oracle](../../median_filter_oracle.py) sorts each trailing window directly instead of using the source's maintained sorted buffer.

## Pinned source

The reference is [`MedianFilter.filter`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/streaming/MedianFilter.java) at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`. Its implementation keeps arrival order for eviction and an ascending copy for median selection.
