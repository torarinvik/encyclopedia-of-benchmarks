# Gabor filter kernel

This package implements the pinned Python `gabor_filter_kernel` function. It generates the two-dimensional kernel only; image loading, OpenCV conversion/convolution, display, and the demo's orientation accumulation are outside the benchmark.

## Contract

Input is six signed 64-bit integers in this order:

`[requested_ksize, sigma, theta_degrees, wavelength, gamma, phase_radians]`

The bounds are `ksize` 1–7, `sigma` 1–8, `theta` 0–359 degrees, `wavelength` 1–8, `gamma` 0–4, and `phase` −6–6 radians. An even requested size is increased by one, matching the source. A seven-element packed input is parseable so the ABI can reject an overlong call; every valid call has exactly six elements.

For each row-major coordinate, the source rotates the centered offsets and computes:

`exp(-(x*x + gamma*gamma*y*y) / (2*sigma*sigma)) * cos(2*pi*x/wavelength + phase)`

The source stores each coefficient in a NumPy `float32` array. The ABI returns the row-major coefficients as little-endian IEEE-754 binary32 bytes. The result is the byte length, `-1` for invalid input, or `-2` when the output pointer is null or its capacity is too small. The maximum kernel is 7×7 and needs 196 output bytes.

## Workload

[`workload.json`](workload.json) covers odd and even sizes, the full output size, orientation and phase changes, parameter boundaries, malformed input, and output-capacity boundaries. [`gabor_filter_oracle.py`](../../gabor_filter_oracle.py) evaluates the source expression and rounds each coefficient to binary32 before encoding it.

## Language ports

| Language | Source |
|---|---|
| C | [`c/g/gabor_filter.c`](../../../c/g/gabor_filter.c) |
| C3 | [`c3/g/gabor_filter.c3`](../../../c3/g/gabor_filter.c3) |
| C++ | [`cpp/g/gabor_filter.cpp`](../../../cpp/g/gabor_filter.cpp) |
| Elisa | [`elisa/g/gabor_filter.elisa`](../../../elisa/g/gabor_filter.elisa) |
| Nim | [`nim/g/gabor_filter.nim`](../../../nim/g/gabor_filter.nim) |
| Odin | [`odin/g/gabor_filter.odin`](../../../odin/g/gabor_filter.odin) |
| Rust | [`rust/g/gabor_filter.rs`](../../../rust/g/gabor_filter.rs) |
| V | [`v/g/gabor_filter.v`](../../../v/g/gabor_filter.v) |
| Zig | [`zig/g/gabor_filter.zig`](../../../zig/g/gabor_filter.zig) |

## Pinned source

[TheAlgorithms/Python `gabor_filter.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/digital_image_processing/filters/gabor_filter.py)
