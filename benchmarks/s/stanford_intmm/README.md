# Stanford IntMM

This package ports the integer matrix multiplication in the pinned Stanford benchmark. It keeps the fixed 40×40 matrices, the source's 16-bit linear congruential generator, full matrix product, and one diagonal output line per pass.

## Source and contract

The pinned source is [`Stanford/IntMM/IntMM.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/IntMM/IntMM.c) at commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Its [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/IntMM/info.sh) compiles `IntMM.c`, supplies `-lm`, and passes no run options. `main` calls `Intmm` ten times with run indices 0 through 9.

The exported function accepts a pass count from 1 through 10. Each pass resets the seed to 74755, fills A and then B in row-major order using `seed = (seed * 1309 + 13849) & 65535`, maps each seed to `seed % 120 - 60`, computes all 40×40 output cells with row, column, and inner indices in increasing order, and emits the diagonal cell selected by that pass. The output is exact signed decimal ASCII followed by LF for each pass. Re-seeding means every pass uses the same matrices; the selected diagonal position advances from 1 through 10 in the source's one-based indexing.

Invalid pass counts return -1. A null output pointer or a buffer shorter than the complete output returns -2 without writing. The largest valid output is 80 bytes. The ten-pass workload case matches the upstream launcher profile and emits ten lines.

## Workload and oracle

[`workload.json`](workload.json) records the pinned launcher and the bounded one-to-ten-pass contract. [`stanford_intmm_oracle.py`](../../stanford_intmm_oracle.py) independently regenerates the two matrices and computes only the diagonal dot products that are visible in the output, rather than constructing a full result matrix. The ports use the existing `i64_scalar_bytes_output` ABI family.

The pinned C source has no explicit license notice; these ports are independently written.

| Language | Port |
|---|---|
| C | [`c/s/stanford_intmm.c`](../../../c/s/stanford_intmm.c) |
| C3 | [`c3/s/stanford_intmm.c3`](../../../c3/s/stanford_intmm.c3) |
| C++ | [`cpp/s/stanford_intmm.cpp`](../../../cpp/s/stanford_intmm.cpp) |
| Elisa | [`elisa/s/stanford_intmm.elisa`](../../../elisa/s/stanford_intmm.elisa) |
| Nim | [`nim/s/stanford_intmm.nim`](../../../nim/s/stanford_intmm.nim) |
| Odin | [`odin/s/stanford_intmm.odin`](../../../odin/s/stanford_intmm.odin) |
| Rust | [`rust/s/stanford_intmm.rs`](../../../rust/s/stanford_intmm.rs) |
| V | [`v/s/stanford_intmm.v`](../../../v/s/stanford_intmm.v) |
| Zig | [`zig/s/stanford_intmm.zig`](../../../zig/s/stanford_intmm.zig) |
