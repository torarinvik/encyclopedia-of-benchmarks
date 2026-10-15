# Circular convolution

Compute the circular convolution of two finite integer signals, wrapping products around the common padded signal length.

## Contract

The `i64_array_bytes_output` input is `[a_length, b_length, a[0..], b[0..]]`. Each length must be in `1..8`, each sample in `[-2, 2]`, and the packed array must contain exactly both declared signals. Let `n = max(a_length, b_length)`; append zeroes to the shorter signal through index `n - 1`. The result is `out[k] = sum(a[i] * b[(k - i) mod n])` for `0 <= i < n`. The successful return value is `n`, and the output buffer contains `n` signed-byte two's-complement values in order. Invalid input returns `-1`; a null or undersized output buffer returns `-2`.

The sample and length bounds keep every sum in `[-32, 32]`. This is circular convolution with wraparound; the Java `convolution` package implements linear convolution and is a separate algorithm contract. The Python source rounds each result to two decimal places, which leaves these bounded integer results unchanged.

## Source

The pinned Python [`circular_convolution.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/electronics/circular_convolution.py) zero-pads both signals to the larger length, forms a circulant matrix, and multiplies it by the first signal before rounding results to two decimal places.

## Workload and recording

[`workload.json`](workload.json) covers wraparound, unequal and equal lengths, positive and negative samples, singleton signals, the maximum sample bounds, and malformed packed inputs.

The shared `i64_array_bytes_output` runner checks the returned byte count and the signed-byte result vector.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm circular_convolution --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/c/circular_convolution/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/c/circular_convolution.c`](../../../c/c/circular_convolution.c) |
| C3 | [`c3/c/circular_convolution.c3`](../../../c3/c/circular_convolution.c3) |
| C++ | [`cpp/c/circular_convolution.cpp`](../../../cpp/c/circular_convolution.cpp) |
| Elisa | [`elisa/c/circular_convolution.elisa`](../../../elisa/c/circular_convolution.elisa) |
| Nim | [`nim/c/circular_convolution.nim`](../../../nim/c/circular_convolution.nim) |
| Odin | [`odin/c/circular_convolution.odin`](../../../odin/c/circular_convolution.odin) |
| Rust | [`rust/c/circular_convolution.rs`](../../../rust/c/circular_convolution.rs) |
| V | [`v/c/circular_convolution.v`](../../../v/c/circular_convolution.v) |
| Zig | [`zig/c/circular_convolution.zig`](../../../zig/c/circular_convolution.zig) |
