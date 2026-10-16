# Laplacian filter

The pinned Python `my_laplacian` uses the listed 3×3 Laplacian kernel when `ksize=1`, then applies OpenCV `filter2D` with correlation, default border handling, and anchor `(0,0)`. This scalar contract reads the output at `(0,0)` from a 3×3 grayscale patch; every referenced pixel is inside the patch, so border extension does not affect the result.

## Contract

The `i64_array_float64` ABI takes exactly nine signed 64-bit values in row-major order, each a grayscale integer in `[0,255]`, and returns one binary64 scalar. The selected kernel is `[[0,-1,0],[-1,4,-1],[0,-1,0]]`. With anchor `(0,0)`, the output at `(0,0)` is `4*pixel(1,1) - pixel(0,1) - pixel(1,0) - pixel(1,2) - pixel(2,1)`. Invalid lengths or pixels return the `-1e300` sentinel; valid outputs are exact integer-valued binary64 numbers. Workload comparisons use zero absolute and relative tolerance.

See [workload](workload.json), [oracle](../../laplacian_filter_oracle.py), and the pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/digital_image_processing/filters/laplacian_filter.py).

| Language | Port |
|---|---|
| C | c/l/laplacian_filter.c |
| C3 | c3/l/laplacian_filter.c3 |
| C++ | cpp/l/laplacian_filter.cpp |
| Elisa | elisa/l/laplacian_filter.elisa |
| Nim | nim/l/laplacian_filter.nim |
| Odin | odin/l/laplacian_filter.odin |
| Rust | rust/l/laplacian_filter.rs |
| V | v/l/laplacian_filter.v |
| Zig | zig/l/laplacian_filter.zig |

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm laplacian_filter --language rust
python3 benchmarks/run_i64_array_float64.py --algorithm laplacian_filter
```
