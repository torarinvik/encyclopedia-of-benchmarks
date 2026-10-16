# Linear convolution

This benchmark follows the pinned Java `Convolution.convolution` method. Given two finite discrete signals `a` and `b`, it returns their full linear convolution in increasing output-index order.

## Contract

- The `i64_array_bytes_output` ABI packs `[a_count, b_count, a..., b...]`.
- Both counts are in `1..=64`; the packed input contains exactly `2 + a_count + b_count` signed 64-bit values. Each sample is in `[-1,000,000, 1,000,000]`.
- The output has `a_count + b_count - 1` coefficients. For each output index `i`, compute `sum(a[k] * b[i-k])` over `max(0, i - b_count + 1) <= k <= min(i, a_count - 1)`. Emit each coefficient as a little-endian signed 64-bit integer. The return value is the output byte length.
- Invalid packing or out-of-domain values return `-1`; a null or undersized output buffer returns `-2`.
- Inputs are restricted to integers so each Java binary64 multiplication and running sum is exact: each coefficient has magnitude at most `64,000,000,000,000`, below `2^53`. The maximum output workspace is 1,016 bytes.

Empty signals are excluded because the pinned method sizes its result as `a.length + b.length - 1`; the bounded benchmark domain keeps both signals nonempty.

## Source and nearby algorithms

The pinned [Java `Convolution.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/Convolution.java) uses nested loops with `kStart = max(0, i - b.length + 1)` and `kEnd = min(i, a.length - 1)`, accumulating `a[k] * b[i-k]` in order. This is full linear convolution. It differs from [`circular_convolution`](../circular_convolution/README.md), which wraps indices, and [`cross_correlation`](../cross_correlation/README.md), which slides one signal in correlation order. The Python `convolve_1d` candidate is centered and truncated to the signal length, so it has a different output contract. The Java `ConvolutionFFT` sibling uses the convolution theorem rather than the direct nested-loop method measured here.

[`workload.json`](workload.json) covers the source formula with unequal and singleton signals, signed and zero samples, the sample bounds, malformed packing, and insufficient output capacity.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/c/convolution.c`](../../../c/c/convolution.c) |
| C3 | [`c3/c/convolution.c3`](../../../c3/c/convolution.c3) |
| C++ | [`cpp/c/convolution.cpp`](../../../cpp/c/convolution.cpp) |
| Elisa | [`elisa/c/convolution.elisa`](../../../elisa/c/convolution.elisa) |
| Nim | [`nim/c/convolution.nim`](../../../nim/c/convolution.nim) |
| Odin | [`odin/c/convolution.odin`](../../../odin/c/convolution.odin) |
| Rust | [`rust/c/convolution.rs`](../../../rust/c/convolution.rs) |
| V | [`v/c/convolution.v`](../../../v/c/convolution.v) |
| Zig | [`zig/c/convolution.zig`](../../../zig/c/convolution.zig) |
