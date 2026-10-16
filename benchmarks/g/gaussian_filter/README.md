# Gaussian Filter

The pinned Python implementation builds a Gaussian kernel, slides it over a grayscale image without padding, computes each row-major window dot product, and casts the result to an unsigned byte. Its demonstration uses a 3×3 kernel with sigma 1 and a 5×5 kernel with sigma 0.8. This package benchmarks those two source configurations; image loading, OpenCV color conversion, and display code are outside the measured function.

## Contract

Input is `[height, width, kernel_size, pixels...]`, with row-major grayscale byte pixels. Height and width are 3 through 12. `kernel_size` is 3 or 5, and each dimension must be at least that large. The 3×3 kernel uses sigma 1; the 5×5 kernel uses sigma 0.8, matching the pinned demo. Invalid input returns `-1`.

The source kernel uses `1 / (2πσ) * exp(-(x²+y²)/(2σ²))` and is not normalized to sum to one. The contract rounds those coefficients once to integer units of `10^-15`, then accumulates integer pixel-weight products and truncates by integer division. This defines a deterministic fixed-point version of the source's formula and byte conversion, with identical results across language runtimes. Output is the valid convolution in row-major order, and the return value is the number of bytes written. Insufficient output capacity returns `-2`.

The maximum input is 147 signed 64-bit values and the maximum output is 100 bytes. See [`workload.json`](workload.json) for the recorded inputs.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/g/gaussian_filter.c`](../../../c/g/gaussian_filter.c) |
| C3 | [`c3/g/gaussian_filter.c3`](../../../c3/g/gaussian_filter.c3) |
| C++ | [`cpp/g/gaussian_filter.cpp`](../../../cpp/g/gaussian_filter.cpp) |
| Elisa | [`elisa/g/gaussian_filter.elisa`](../../../elisa/g/gaussian_filter.elisa) |
| Nim | [`nim/g/gaussian_filter.nim`](../../../nim/g/gaussian_filter.nim) |
| Odin | [`odin/g/gaussian_filter.odin`](../../../odin/g/gaussian_filter.odin) |
| Rust | [`rust/g/gaussian_filter.rs`](../../../rust/g/gaussian_filter.rs) |
| V | [`v/g/gaussian_filter.v`](../../../v/g/gaussian_filter.v) |
| Zig | [`zig/g/gaussian_filter.zig`](../../../zig/g/gaussian_filter.zig) |

## Pinned source

[TheAlgorithms/Python `gaussian_filter.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/digital_image_processing/filters/gaussian_filter.py)
