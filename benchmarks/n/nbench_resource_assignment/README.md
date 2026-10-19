# NBench resource assignment

This package implements a bounded deterministic version of NBench's resource-assignment kernel. It performs the row and column cost reductions, greedy zero assignments, and tableau adjustments used by the kernel's Hungarian-method assignment routine. Input costs replace the source benchmark's generated random matrix.

The input is [n, cost_00, cost_01, ..., cost_(n-1,n-1)], with an n × n row-major cost matrix, 1 <= n <= 8, and costs in [0,1000]. The result is one zero-based assigned column per row, encoded as little-endian signed 32-bit integers. The runner ABI returns the output byte count, -1 for invalid input, and -2 for null or undersized output; errors write no output.

This is an algorithm-kernel workload, not an official NBench result. It is based on ANSIbench's NBench BYTEmark source nbench/src/nbench1.c (DoAssign, first_assignments, and second_assignments) at [nfinit/ansibench commit ef90abd09d7b7bb1f2809f896d6f67fb9724bebe](https://github.com/nfinit/ansibench/blob/ef90abd09d7b7bb1f2809f896d6f67fb9724bebe/nbench/src/nbench1.c). NBench credits Rick Grehan/BYTE Magazine for BYTEmark and Uwe F. Mayer for the Linux/Unix port. The implementation is written independently; no source blocks are copied.

The upstream BYTEmark notice makes its source, executable, and documentation available “as is” and disclaims warranties and liability. Preserve the notice and attribution when redistributing derived work; the upstream package is commonly tagged freedist, not a standard permissive license. See the copied [LICENSE](LICENSE) notice.
