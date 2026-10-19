# LAC-DCC `fp-convert`

This package models the pinned benchmark's float-conversion dot-product loop. Each outer iteration creates two length-2048 float32 vectors from scalar offsets and the element index, accumulates their elementwise products in float64, and adds that dot product to a float64 total. The source's offset state uses float32 updates every tenth outer iteration and resets on the other iterations.

## Contract

The `float64_slice_io` symbol is `misc_fp_convert(input, input_length, output, output_capacity)`. Input is exactly one finite float64 containing an integer iteration count from 1 through 256. The profile is bounded below the source's default 500,000 iterations (100,000 with `SMALL_PROBLEM_SIZE`). The ports preserve float32 conversion and offset updates, the 2,048-element dot-product order, and float64 accumulation. The function returns one numeric float64 total. Invalid input returns -1; null output or capacity below one returns -2 without writing. Comparison tolerances are absolute `1e-7` and relative `1e-12`.

This numeric ABI omits the source's `Total is %g` display formatting. See [workload.json](workload.json) and the independent [oracle](../../misc_fp_convert_oracle.py).

## Pinned source

- [fp-convert.c at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/fp-convert/fp-convert.c)
- [info.sh at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/fp-convert/info.sh)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/m/misc_fp_convert.c](../../../c/m/misc_fp_convert.c) |
| C3 | [c3/m/misc_fp_convert.c3](../../../c3/m/misc_fp_convert.c3) |
| C++ | [cpp/m/misc_fp_convert.cpp](../../../cpp/m/misc_fp_convert.cpp) |
| Elisa | [elisa/m/misc_fp_convert.elisa](../../../elisa/m/misc_fp_convert.elisa) |
| Nim | [nim/m/misc_fp_convert.nim](../../../nim/m/misc_fp_convert.nim) |
| Odin | [odin/m/misc_fp_convert.odin](../../../odin/m/misc_fp_convert.odin) |
| Rust | [rust/m/misc_fp_convert.rs](../../../rust/m/misc_fp_convert.rs) |
| V | [v/m/misc_fp_convert.v](../../../v/m/misc_fp_convert.v) |
| Zig | [zig/m/misc_fp_convert.zig](../../../zig/m/misc_fp_convert.zig) |
