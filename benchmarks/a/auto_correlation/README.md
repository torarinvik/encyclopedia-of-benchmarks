# Auto-correlation signal

Compute the full linear auto-correlation signal of a finite integer sequence, using the pinned Java implementation's cross-correlation procedure.

## Contract

The `i64_array_bytes_output` input is `[count, samples...]`, with `count` in `1..64`, exactly `count` samples, and each sample in `[-1,000,000, 1,000,000]`. The result has `2 * count - 1` coefficients. For each output index, overlap the signal with itself shifted across the full linear range and sum the pairwise products; no normalization, mean subtraction, or circular wraparound is applied.

The successful return value is the output byte length. Each coefficient is encoded as a signed 64-bit two's-complement integer in little-endian order. Invalid input returns `-1`; a null or undersized output buffer returns `-2`.

The pinned Java implementation returns `double[]`, but this bounded domain makes every dot product an exact integer: the largest magnitude is `64 * 1,000,000^2 = 64,000,000,000,000`, below both the signed 64-bit limit and the exact-integer limit of binary64. The byte output therefore stores those exact coefficient values directly as i64.

## Source

The pinned Java [`AutoCorrelation.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/AutoCorrelation.java) calls its [`CrossCorrelation.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/CrossCorrelation.java) implementation with the signal as both inputs. Its result has `2 * count - 1` entries. This differs from the `autocorrelation` package, which returns a normalized scalar for one selected lag.

## Workload and recording

[`workload.json`](workload.json) covers the pinned example, positive and negative samples, a singleton, zeroes, the largest sample magnitude, and malformed packed arrays.

The shared `i64_array_bytes_output` runner validates the packed input and compares the returned signed-i64 byte sequence.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm auto_correlation --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/a/auto_correlation/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/a/auto_correlation.c`](../../../c/a/auto_correlation.c) |
| C3 | [`c3/a/auto_correlation.c3`](../../../c3/a/auto_correlation.c3) |
| C++ | [`cpp/a/auto_correlation.cpp`](../../../cpp/a/auto_correlation.cpp) |
| Elisa | [`elisa/a/auto_correlation.elisa`](../../../elisa/a/auto_correlation.elisa) |
| Nim | [`nim/a/auto_correlation.nim`](../../../nim/a/auto_correlation.nim) |
| Odin | [`odin/a/auto_correlation.odin`](../../../odin/a/auto_correlation.odin) |
| Rust | [`rust/a/auto_correlation.rs`](../../../rust/a/auto_correlation.rs) |
| V | [`v/a/auto_correlation.v`](../../../v/a/auto_correlation.v) |
| Zig | [`zig/a/auto_correlation.zig`](../../../zig/a/auto_correlation.zig) |
