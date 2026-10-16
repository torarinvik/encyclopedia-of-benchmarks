# Canny edge detection

This benchmark extracts the pinned Python Canny pipeline into a portable grayscale-image contract. It applies a 9×9 Gaussian blur, absolute Sobel derivatives, independent gradient normalization, directional non-maximum suppression, the source thresholds, and its row-major one-pass hysteresis.

## Contract

- Input is `[side, pixel_0, ..., pixel_(side*side-1)]`, with row-major grayscale bytes and `side` in `1..=16`.
- Each pixel is in `0..=255`. The image must contain exactly `side*side` pixels.
- Return the number of output pixels and write one byte per pixel: `255` for retained strong edges and `0` otherwise.
- Malformed input returns `-1`; insufficient output capacity returns `-2` without writing.
- Gaussian weights and normalized Sobel values use deterministic fixed-point arithmetic. This avoids platform-specific SIMD and floating-point threshold drift.
- The input cap bounds each image to 256 pixels. Runtime is O(side²) for this fixed 9×9 kernel and extra space is O(side²).

The upstream demo imports OpenCV to load/display a sample image, while its core function uses NumPy and two included filter helpers. Those display and array-package dependencies are removed in these ports. The helper's Gaussian filter is replicated with edge padding. The upstream hysteresis loop accesses neighbors past the bottom and right borders; this contract safely scans only interior pixels while preserving its single row-major pass, so weak edges only connect to already-strong neighbors encountered by that pass. Since the source takes absolute Sobel components before calculating direction, its reachable suppression directions are horizontal, vertical, and the northeast/southwest diagonal. When an entire Sobel component is zero, its normalized component is defined as zero.

## Workload and verification

`workload.json` covers small and constant images, vertical/horizontal/diagonal edges, impulses, checkerboards, deterministic texture, malformed dimensions/pixels, and output-capacity failures. The verifier adds seeded images and compares all nine ports with a separately implemented fixed-point image oracle.

Run all nine implementations with:

```sh
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm canny --elisa-compiler ../Elisa-compiler/bin/elisac-stage1
```

## Pinned source

- [TheAlgorithms/Python `canny.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/digital_image_processing/edge_detection/canny.py)
- [Gaussian convolution helper](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/digital_image_processing/filters/convolve.py)
- [Sobel filter helper](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/digital_image_processing/filters/sobel_filter.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/c/canny.c](../../../c/c/canny.c) |
| C3 | [c3/c/canny.c3](../../../c3/c/canny.c3) |
| C++ | [cpp/c/canny.cpp](../../../cpp/c/canny.cpp) |
| Elisa | [elisa/c/canny.elisa](../../../elisa/c/canny.elisa) |
| Nim | [nim/c/canny.nim](../../../nim/c/canny.nim) |
| Odin | [odin/c/canny.odin](../../../odin/c/canny.odin) |
| Rust | [rust/c/canny.rs](../../../rust/c/canny.rs) |
| V | [v/c/canny.v](../../../v/c/canny.v) |
| Zig | [zig/c/canny.zig](../../../zig/c/canny.zig) |
