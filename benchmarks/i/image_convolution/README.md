# Image Convolution

Apply an odd square kernel to a square grayscale image, using edge replication for samples beyond the image boundary.

## Contract

- The `i64_array_bytes_output` input is `[side, kernel_side, row-major pixels, row-major kernel weights]`.
- `side` is 1–16. Pixels are byte grayscale values, 0–255. `kernel_side` is an odd value from 1–7, and each weight is from -16 to 16.
- For output coordinate `(y, x)`, the kernel window is centered at that pixel. Each source coordinate outside `[0, side)` is clamped to the nearest image edge. The kernel remains in its given row-major orientation; its elements are not reversed.
- The output is `side*side` exact signed 64-bit values in row-major order, encoded little-endian. Invalid input returns `-1`; an undersized output buffer returns `-2`.

## Source semantics

The pinned [Python `convolve.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/digital_image_processing/filters/convolve.py) defines `img_convolve` by edge-padding the image and taking a dot product between each flattened image window and the flattened filter. That operation preserves kernel orientation. Its helper assumes square images: the `im2col` loop dimensions are swapped, so rectangular inputs can produce incomplete windows or fail when reshaping. Even kernels also produce a different padded output size and do not fit the source's same-size reshape. The shared contract restricts inputs to square images and odd square kernels, where the source's operation is well-defined. The demo's OpenCV loading, grayscale conversion, display, key wait, and uint8 cast are excluded. The upstream Python repository is MIT licensed.

## Workload

[`workload.json`](workload.json) covers a one-pixel image, edge replication, an asymmetric kernel to expose orientation, a box filter, the largest image/kernel pair, invalid values and shapes, malformed input, and insufficient output capacity. The oracle is [`image_convolution_oracle.py`](../../image_convolution_oracle.py). All nine implementations build and pass the 13 workload cases.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/i/image_convolution.c`](../../../c/i/image_convolution.c) |
| C3 | [`c3/i/image_convolution.c3`](../../../c3/i/image_convolution.c3) |
| C++ | [`cpp/i/image_convolution.cpp`](../../../cpp/i/image_convolution.cpp) |
| Elisa | [`elisa/i/image_convolution.elisa`](../../../elisa/i/image_convolution.elisa) |
| Nim | [`nim/i/image_convolution.nim`](../../../nim/i/image_convolution.nim) |
| Odin | [`odin/i/image_convolution.odin`](../../../odin/i/image_convolution.odin) |
| Rust | [`rust/i/image_convolution.rs`](../../../rust/i/image_convolution.rs) |
| V | [`v/i/image_convolution.v`](../../../v/i/image_convolution.v) |
| Zig | [`zig/i/image_convolution.zig`](../../../zig/i/image_convolution.zig) |

