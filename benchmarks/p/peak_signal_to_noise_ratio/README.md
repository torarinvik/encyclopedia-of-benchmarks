# Peak signal-to-noise ratio

The pinned Python implementation computes the mean squared pixel difference and returns `20 * log10(255 / sqrt(MSE))`, except it returns 100 when MSE is zero. The pinned Rust implementation uses the same formula for nonzero MSE but returns positive infinity for identical images.

## Contract

Input is `[pixel_count, original_pixels..., compressed_pixels...]` with 1–64 u8 pixels in each equally sized array. Pixel values are 0–255, and each original/compressed pair may differ by at most 15. The Python source loads u8 image arrays and computes the square before converting to a mean; differences above 15 can overflow that u8 square, while Rust converts each difference to f64 first. The bound keeps every squared error at or below 225 so the sources agree. At least one pixel must differ; identical arrays are excluded because Python returns 100 while Rust returns positive infinity. The output is binary64 decibels; malformed, identical, or out-of-domain inputs return `-1e300`.

The image-loading and OpenCV/NumPy setup in the Python driver is presentation context; the benchmark supplies pixel arrays directly. See [`workload.json`](workload.json) and the runtime [oracle](../../peak_signal_to_noise_ratio_oracle.py).

## Build and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm peak_signal_to_noise_ratio --language rust --with-checker
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/p/peak_signal_to_noise_ratio/rust/build.json
python3 benchmarks/verify_i64_array_float64.py --algorithm peak_signal_to_noise_ratio
```

Pinned sources: [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_compression/peak_signal_to_noise_ratio.py) and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/compression/peak_signal_to_noise_ratio.rs).

| Language | Port |
|---|---|
| C | [`c/p/peak_signal_to_noise_ratio.c`](../../../c/p/peak_signal_to_noise_ratio.c) |
| C3 | [`c3/p/peak_signal_to_noise_ratio.c3`](../../../c3/p/peak_signal_to_noise_ratio.c3) |
| C++ | [`cpp/p/peak_signal_to_noise_ratio.cpp`](../../../cpp/p/peak_signal_to_noise_ratio.cpp) |
| Elisa | [`elisa/p/peak_signal_to_noise_ratio.elisa`](../../../elisa/p/peak_signal_to_noise_ratio.elisa) |
| Nim | [`nim/p/peak_signal_to_noise_ratio.nim`](../../../nim/p/peak_signal_to_noise_ratio.nim) |
| Odin | [`odin/p/peak_signal_to_noise_ratio.odin`](../../../odin/p/peak_signal_to_noise_ratio.odin) |
| Rust | [`rust/p/peak_signal_to_noise_ratio.rs`](../../../rust/p/peak_signal_to_noise_ratio.rs) |
| V | [`v/p/peak_signal_to_noise_ratio.v`](../../../v/p/peak_signal_to_noise_ratio.v) |
| Zig | [`zig/p/peak_signal_to_noise_ratio.zig`](../../../zig/p/peak_signal_to_noise_ratio.zig) |
