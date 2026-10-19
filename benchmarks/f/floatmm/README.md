# Stanford FloatMM

This package ports the pinned [`FloatMM.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/FloatMM/FloatMM.c) kernel and its [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/FloatMM/info.sh) launcher. The launcher selects `FloatMM.c`, links `-lm`, and passes no run options.

## Contract

The `i64_scalar_bytes_output` ABI accepts an integer pass count from 0 through 40. Each pass resets the source's 16-bit random seed, initializes two 40×40 matrices in row-major order, computes the full matrix product using single-precision values and the source's row, column, and inner-index order, then emits that pass's diagonal result using six fractional digits and a newline. The return value is the number of output bytes. Zero passes return zero and an empty output. Invalid pass counts return `-1`; a null or short output buffer for positive output returns `-2` without writing.

The upstream `main` performs 5,000 products. It prints only the first 40 diagonal values; later products repeat the same deterministic work without printing. This bounded profile preserves those first 40 printed passes and caps work at 40 products. Its maximum output is 560 bytes. The independent [oracle](../../floatmm_oracle.py) reproduces the binary32 operation order and fixed `%f` output rounding. The workload covers zero, partial, and full output, invalid bounds, null output, and insufficient capacity.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/floatmm.c`](../../../c/f/floatmm.c) |
| C3 | [`c3/f/floatmm.c3`](../../../c3/f/floatmm.c3) |
| C++ | [`cpp/f/floatmm.cpp`](../../../cpp/f/floatmm.cpp) |
| Elisa | [`elisa/f/floatmm.elisa`](../../../elisa/f/floatmm.elisa) |
| Nim | [`nim/f/floatmm.nim`](../../../nim/f/floatmm.nim) |
| Odin | [`odin/f/floatmm.odin`](../../../odin/f/floatmm.odin) |
| Rust | [`rust/f/floatmm.rs`](../../../rust/f/floatmm.rs) |
| V | [`v/f/floatmm.v`](../../../v/f/floatmm.v) |
| Zig | [`zig/f/floatmm.zig`](../../../zig/f/floatmm.zig) |

Build and record a port with the shared ABI commands:

```sh
python3 benchmarks/build_abi.py --family i64_scalar_bytes_output --algorithm floatmm --language c
python3 benchmarks/run_i64_scalar_bytes_output.py --build-manifest build/i64_scalar_bytes_output/f/floatmm/c/build.json
```
