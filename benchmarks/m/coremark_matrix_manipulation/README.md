# CoreMark matrix manipulation kernel

This is a bounded matrix-kernel variant based on EEMBC's CoreMark `matrix_test`; it is not an official CoreMark benchmark or score. It fixes the dimension at 3 and accepts the matrices explicitly so the work is deterministic.

## Contract

Input is exactly `[value, A row-major (9 values), B row-major (9 values)]`. `value` is 0–15 and each matrix value is 0–127. These bounds keep `MATDAT` values within signed 16-bit range and all products and accumulations within signed 32-bit range. The clip threshold is the source expression `0xf000 | value`, converted to signed 16-bit `MATDAT` (a negative value for this profile).

The kernel executes `matrix_test` in source order: add `value` to A; multiply A by the constant; multiply A by the vector in `B[0..2]`; multiply A by B; multiply A by B again while applying the source bit extraction to each product; and run `matrix_sum` after each of those four result matrices. `matrix_sum` retains its row-major accumulator, strict `tmp > clipval` clipping, reset behavior, and comparison with the previous element. The source-style CRC16 is updated from the four signed 16-bit sums in order. Finally, `-value` is added back to A.

Output is fourteen little-endian signed 64-bit values: `[crc16, matrix_sum[4], restored_A[9]]`. The vector stage retains C's untouched six entries from the preceding multiply-constant stage when computing its `matrix_sum`, as the source does. Success returns 112 bytes; invalid input returns `-1`; null or short output returns `-2`; errors leave output untouched.

## Source and license

The operation follows `matrix_test`, `matrix_sum`, and the matrix helpers in [`coremark/src/core_matrix.c` at nfinit/ansibench commit ef90abd09d7b7bb1f2809f896d6f67fb9724bebe](https://github.com/nfinit/ansibench/blob/ef90abd09d7b7bb1f2809f896d6f67fb9724bebe/coremark/src/core_matrix.c). CoreMark is a registered EEMBC trademark; this modified, bounded derivative is identified as a kernel variant and is not associated with an official score. Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC); original author Shay Gal-on. The source is Apache License 2.0. The upstream [`LICENSE.md`](https://github.com/nfinit/ansibench/blob/ef90abd09d7b7bb1f2809f896d6f67fb9724bebe/coremark/LICENSE.md), including its acceptable-use and trademark terms, is included unchanged as [`LICENSE.md`](LICENSE.md). Preserve the license and attribution when redistributing.

## Workload and oracle

The independent oracle is [`benchmarks/coremark_matrix_manipulation_oracle.py`](../../coremark_matrix_manipulation_oracle.py). Ports are provided in C, C++, C3, Rust, Nim, Odin, V, Zig, and Elisa.
