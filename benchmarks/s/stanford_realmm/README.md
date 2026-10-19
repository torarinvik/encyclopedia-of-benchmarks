# Stanford RealMM

This package ports the double-precision matrix multiplication in the pinned Stanford RealMM benchmark.

## Source and contract

The pinned source is [`Stanford/RealMM/RealMM.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/RealMM/RealMM.c) at commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Its [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/RealMM/info.sh) compiles `RealMM.c` with `-lm` and runs without options. The source initializes two 40×40 matrices from its 16-bit LCG, computes the full double-precision product in row, column, then inner-index order, and prints one diagonal product per run with `printf("%f\n", value)`. `main` runs ten passes; each pass resets the random seed and regenerates the same A and B matrices.

The suite accepts `pass_count` in 1..10. Each pass reseeds to 74755, regenerates A and B in row-major order, maps each generated integer to `(temp % 120 - 60) / 3.0`, computes the full 40×40 product in source order, and emits the matching diagonal element. Output uses six fractional digits, C `%f` round-to-nearest formatting, and LF. Ten passes reproduce the launcher's output profile.

The `stanford_realmm(pass_count, output, output_capacity)` entry point uses the existing `i64_scalar_bytes_output` ABI family. It returns the exact ASCII byte count, -1 for an invalid pass count, and -2 for a null or undersized output buffer; output is staged before copying, so errors write nothing. The maximum output is 140 bytes.

## Workload and oracle

[`workload.json`](workload.json) describes the bounded contract, launcher profile, and capacity/error cases. [`stanford_realmm_oracle.py`](../../stanford_realmm_oracle.py) independently regenerates both matrices and computes only the visible diagonal dot products instead of constructing the full product. The language ports retain the full source computation for every pass.

The pinned C file has no explicit license notice; these implementations are independently written.

| Language | Port |
|---|---|
| C | [`c/s/stanford_realmm.c`](../../../c/s/stanford_realmm.c) |
| C3 | [`c3/s/stanford_realmm.c3`](../../../c3/s/stanford_realmm.c3) |
| C++ | [`cpp/s/stanford_realmm.cpp`](../../../cpp/s/stanford_realmm.cpp) |
| Elisa | [`elisa/s/stanford_realmm.elisa`](../../../elisa/s/stanford_realmm.elisa) |
| Nim | [`nim/s/stanford_realmm.nim`](../../../nim/s/stanford_realmm.nim) |
| Odin | [`odin/s/stanford_realmm.odin`](../../../odin/s/stanford_realmm.odin) |
| Rust | [`rust/s/stanford_realmm.rs`](../../../rust/s/stanford_realmm.rs) |
| V | [`v/s/stanford_realmm.v`](../../../v/s/stanford_realmm.v) |
| Zig | [`zig/s/stanford_realmm.zig`](../../../zig/s/stanford_realmm.zig) |
