# Bilateral filter

Apply an edge-preserving bilateral filter to a bounded grayscale image. Each output pixel combines a spatial Gaussian weight with a range Gaussian weight based on intensity difference from the center pixel.

## Contract

- Input is `[height, width, kernel_size, spatial_variance_millionths, intensity_variance_millionths, pixels...]`, with row-major normalized grayscale pixels. Height and width are 1–32, kernel size is 1, 3, 5, or 7, and all pixel/variance values are represented in millionths from 0–1,000,000 (variances must be positive).
- Output is a row-major image of signed 64-bit millionths, rounded to nearest with ties upward. The border is zero padded, matching the source’s output initialization and interior-only iteration. The function returns the output byte count; invalid input returns `-1`, and insufficient output capacity returns `-2`.
- The Gaussian normalizing constants are omitted because each is uniform across its corresponding weight set and cancels in the normalized weighted average. The double-precision calculation uses the standard exponential function and portable scalar operations.

## Source normalization

The pinned Python source accepts a NumPy grayscale matrix, scales image values to 0–1 in its CLI, and delegates exponentials and array operations to NumPy. This contract replaces those dependencies with a bounded row-major integer interface. Its 2D algorithm is preserved, while OpenCV file loading and display are excluded.

## Workload and verification

[`workload.json`](workload.json) covers flat, impulse, edge, ramp, kernel-one, undersized-image, maximum-kernel, malformed-input, and capacity cases. Verify with `python3 benchmarks/verify_bilateral_filter.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1`.

## Pinned source

- TheAlgorithms/Python [`bilateral_filter.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/digital_image_processing/filters/bilateral_filter.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/bilateral_filter.c`](../../../c/b/bilateral_filter.c) |
| C3 | [`c3/b/bilateral_filter.c3`](../../../c3/b/bilateral_filter.c3) |
| C++ | [`cpp/b/bilateral_filter.cpp`](../../../cpp/b/bilateral_filter.cpp) |
| Elisa | [`elisa/b/bilateral_filter.elisa`](../../../elisa/b/bilateral_filter.elisa) |
| Nim | [`nim/b/bilateral_filter.nim`](../../../nim/b/bilateral_filter.nim) |
| Odin | [`odin/b/bilateral_filter.odin`](../../../odin/b/bilateral_filter.odin) |
| Rust | [`rust/b/bilateral_filter.rs`](../../../rust/b/bilateral_filter.rs) |
| V | [`v/b/bilateral_filter.v`](../../../v/b/bilateral_filter.v) |
| Zig | [`zig/b/bilateral_filter.zig`](../../../zig/b/bilateral_filter.zig) |
