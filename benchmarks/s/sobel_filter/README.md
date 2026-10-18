# Sobel Filter

This benchmark measures the pinned Python image filter's normalized absolute-gradient calculation for a square grayscale image.

## Contract

Input is a signed-i64 array `[side, pixel_0, ..., pixel_(side*side-1)]`. `side` is 3 through 16. Pixels are unsigned grayscale values from 0 through 255 in row-major order. Input length must equal `1 + side*side`; 257 words is the maximum valid length and 258 words is parseable for a trailing-data check.

At each pixel, correlate the image with the following row-major kernels, replicating the nearest image edge for out-of-bounds samples:

```text
Kx = -1  0  1       Ky =  1  2  1
     -2  0  2            0  0  0
     -1  0  1           -1 -2 -1
```

The kernels are not reversed. Take the absolute value of each response. Scale the two axes independently so their respective maxima become 255. Compute `sqrt(dx*dx + dy*dy)`, scale that magnitude image so its maximum becomes 255, and truncate each value to an unsigned 8-bit integer. Compute `theta = atan2(dy, dx)` from the independently normalized, nonnegative axes. This source discards gradient signs, so theta is in `[0, pi/2]` and is not the canonical signed Sobel orientation.

The input domain requires both axis maxima to be nonzero; flat images and images with only horizontal or only vertical response are invalid because the source normalization would divide by zero. Pixels with zero response on both axes are allowed and produce a magnitude of zero and `atan2(0, 0) == 0`.

Output is a float64 vector containing the row-major magnitude pixels widened exactly from uint8, followed by the row-major theta values. It contains `2*side*side` IEEE-754 binary64 values in little-endian order, at most 512 values or 4096 bytes. Comparison uses absolute and relative tolerances of `1e-12`. Output capacity is measured in bytes, and the exported function returns the number of float64 elements written. Malformed or out-of-domain input returns `-1` before output checks. A null output pointer or capacity below the full output size returns `-2`; errors write no output.

## Pinned sources

- Python [`sobel_filter.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/digital_image_processing/filters/sobel_filter.py), commit `e1a2a8b016001309a73d5fec4818c35cca139795`.
- Its convolution helper is [`convolve.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/digital_image_processing/filters/convolve.py) at the same commit. Its edge padding and row-major dot product define the border and kernel-orientation behavior above.

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Oracle: [`benchmarks/sobel_filter_oracle.py`](../../sobel_filter_oracle.py)

## Language ports

| Language | Port |
|---|---|
| C | [`c/s/sobel_filter.c`](../../../c/s/sobel_filter.c) |
| C3 | [`c3/s/sobel_filter.c3`](../../../c3/s/sobel_filter.c3) |
| C++ | [`cpp/s/sobel_filter.cpp`](../../../cpp/s/sobel_filter.cpp) |
| Elisa | [`elisa/s/sobel_filter.elisa`](../../../elisa/s/sobel_filter.elisa) |
| Nim | [`nim/s/sobel_filter.nim`](../../../nim/s/sobel_filter.nim) |
| Odin | [`odin/s/sobel_filter.odin`](../../../odin/s/sobel_filter.odin) |
| Rust | [`rust/s/sobel_filter.rs`](../../../rust/s/sobel_filter.rs) |
| V | [`v/s/sobel_filter.v`](../../../v/s/sobel_filter.v) |
| Zig | [`zig/s/sobel_filter.zig`](../../../zig/s/sobel_filter.zig) |
