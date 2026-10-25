# SciMark2 SOR grid relaxation

This package ports the SciMark2 C kernel's in-place two-dimensional
successive-over-relaxation update. The pinned SciMark driver calls the kernel
with fixed `omega = 1.25`; the bounded profile retains that non-unit value,
the five-point stencil, and the source's pass/row/column order. It is distinct
from the local [`gauss_seidel_method`](../gauss_seidel_method/README.md): that
package solves a bounded linear system with unweighted coordinate updates
(`omega = 1`), while this kernel performs a weighted 2D grid relaxation.

## Contract

- ABI: `i64_array_scalar`, symbol `scimark2_sor`.
- Input is `[rows, columns, iterations, row_major_grid...]`. Rows and columns
  range from 2 through 8; iterations range from 0 through 8. Grid cells are
  signed milli-units in `[-1000,1000]` and represent values divided by 1,000.
- The source's `omega=1.25` recurrence is preserved in fixed point. For each
  interior cell in ascending row-major order, compute
  `trunc_toward_zero((1250*(up+down+left+right)-1000*center)/4000)`.
  Updates are in place, so left and upper neighbors may already have changed
  during the current pass. Boundary cells remain unchanged.
- The scalar result is the weighted row-major checksum
  `sum((flat_index+1)*final_cell)` in the same milli-unit representation.
- Invalid framing, dimensions, iteration counts, or cells return `-1`.

The fixed-point projection keeps all nine ports and the oracle exact while
retaining the source's weighted in-place relaxation behavior. The input grid
is explicit and deterministic; random matrix initialization, timing, cycle
doubling, and the benchmark's Mflop reporting are outside the kernel contract.
The independent Python [oracle](../../scimark2_sor_oracle.py) applies the
recurrence with a separately defined truncation-toward-zero helper.

## Provenance and rights

The pinned launcher compiles `SOR.c` with `-lm` as part of the broader SciMark2
suite. `SOR_execute` is called by the source driver with `omega=1.25`; the
kernel itself updates the interior grid points in place. The pinned SciMark2-C
subtree contains no explicit license or redistribution notice in `SOR.c`,
`SOR.h`, or its README, so this package does not infer rights from a separate
SciMark Java distribution. The ports and oracle are independently written
from the recurrence and do not copy upstream source text.

- [`SOR.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/SciMark2-C/SOR.c)
- [`SOR.h`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/SciMark2-C/SOR.h)
- [`kernel.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/SciMark2-C/kernel.c)
- [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/SciMark2-C/info.sh)

## Language ports

| Language | Source |
| --- | --- |
| C | [c/s/scimark2_sor.c](../../../c/s/scimark2_sor.c) |
| C3 | [c3/s/scimark2_sor.c3](../../../c3/s/scimark2_sor.c3) |
| C++ | [cpp/s/scimark2_sor.cpp](../../../cpp/s/scimark2_sor.cpp) |
| Elisa | [elisa/s/scimark2_sor.elisa](../../../elisa/s/scimark2_sor.elisa) |
| Nim | [nim/s/scimark2_sor.nim](../../../nim/s/scimark2_sor.nim) |
| Odin | [odin/s/scimark2_sor.odin](../../../odin/s/scimark2_sor.odin) |
| Rust | [rust/s/scimark2_sor.rs](../../../rust/s/scimark2_sor.rs) |
| V | [v/s/scimark2_sor.v](../../../v/s/scimark2_sor.v) |
| Zig | [zig/s/scimark2_sor.zig](../../../zig/s/scimark2_sor.zig) |
