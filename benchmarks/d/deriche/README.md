# Deriche recursive image filter

This package ports the `PolyBench/medley/deriche/deriche.c` kernel at upstream commit [`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/commit/5d7b75df749241efa7a6e6f5be613d3fcc5cce38). The source's default type is binary32 and its alpha parameter is fixed at `0.25`. It initializes a grayscale image with `((313*i + 991*j) mod 65536) / 65535`, then performs forward and reverse recurrences along each axis to produce the filtered image.

The `deriche` slug accepts signed 64-bit values `[width, height, passes]`. Width and height are each bounded to 1–32, and passes are bounded to 1–4. Each pass applies the full recursive filter to the preceding pass's output. After the last pass, the result is the binary64 sum of the final binary32 pixels in row-major order. Invalid inputs return `-1e300`.

The benchmark uses the suite's `i64_array_float64` ABI. Build and run it with the regular suite commands:

```sh
python3 benchmarks/build_abi.py --algorithm deriche --language c
python3 benchmarks/run_i64_array_float64.py --algorithm deriche --language c
```

Ports are provided in C, C3, C++, Elisa, Nim, Odin, Rust, V, and Zig. The kernel file has no inline license header; the PolyBench repository-level Ohio State Software Distribution License is reproduced in this package's [`LICENSE.txt`](LICENSE.txt).
