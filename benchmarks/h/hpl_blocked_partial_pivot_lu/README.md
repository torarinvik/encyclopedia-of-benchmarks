# HPL blocked partial-pivot LU

This package isolates a serial, bounded right-looking blocked LU factorization
with row partial pivoting. The algorithm family follows the official Netlib
[HPL algorithm description](https://netlib.sandia.gov/benchmark/hpl/algorithm.html),
which describes right-looking LU with partial pivoting in block panels. This
profile fixes the block width at two, bounds `n` to 2 through 8, and makes
pivot ties deterministic by choosing the smallest current row index. It omits
the distributed block-cyclic matrix layout, MPI communication, look-ahead,
process-grid choices, and benchmark-scale tuning.

The `float64_slice_io` input is `[n, A row-major]`, with exactly `1+n*n`
elements. Every matrix entry must be a finite exact integer in `[-16,16]`.
For each two-column panel, the kernel selects the largest absolute pivot in
the current column, swaps complete rows, factors the panel, solves the panel
block row, and updates the trailing matrix. The output contains `n` zero-based
pivot row indices followed by the compact row-major LU matrix: strict lower
entries hold multipliers, the diagonal and upper triangle hold `U`, and the
unit diagonal of `L` is implicit. A zero maximum pivot is singular and returns
`-1`; no zero-pivot continuation is attempted. Malformed input also returns
`-1`. A null or undersized output returns `-2` without writes after valid
factorization. Successful output length is `n+n*n`, at most 72 doubles; the
declared internal workspace bound is 2048 bytes.

The primary reference follows the two-column panel schedule. The independent
reference uses ordinary one-column partial-pivot elimination, then compares
the pivot vector and compact LU values within `1e-10` absolute and relative
tolerance. The fixtures include a pivot swap, a no-swap case, a swap inside a
panel, a maximum-size diagonal matrix, singular input, malformed framing, and
output-buffer errors.

## Distinction from local LU packages

[`blocked_lu_factorization`](../../b/blocked_lu_factorization/README.md) uses
a width-two blocked schedule but has no pivoting and requires strict diagonal
dominance. [`linpack_lu_solve`](../../l/linpack_lu_solve/README.md) uses scalar
partial-pivot LU as part of a solve operation; this package returns the
factorization and pivot trace while exercising a blocked panel/update
schedule. The profile is a serial kernel only and does not claim to reproduce
full HPL's distributed benchmark.

## References and fixtures

- Blocked primary reference: [`primary_oracle.py`](primary_oracle.py)
- Scalar partial-pivot reference: [`independent_oracle.py`](independent_oracle.py)
- Workload: [`workload.json`](workload.json)
- Static package inventory: [`INVENTORY.json`](INVENTORY.json)
- Static checker: [`check_inventory.py`](check_inventory.py)

## Ports

- C: [`c/h/hpl_blocked_partial_pivot_lu.c`](../../../c/h/hpl_blocked_partial_pivot_lu.c)
- C3: [`c3/h/hpl_blocked_partial_pivot_lu.c3`](../../../c3/h/hpl_blocked_partial_pivot_lu.c3)
- C++: [`cpp/h/hpl_blocked_partial_pivot_lu.cpp`](../../../cpp/h/hpl_blocked_partial_pivot_lu.cpp)
- Elisa: [`elisa/h/hpl_blocked_partial_pivot_lu.elisa`](../../../elisa/h/hpl_blocked_partial_pivot_lu.elisa)
- Mojo: [`mojo/h/hpl_blocked_partial_pivot_lu.mojo`](../../../mojo/h/hpl_blocked_partial_pivot_lu.mojo)
- Nim: [`nim/h/hpl_blocked_partial_pivot_lu.nim`](../../../nim/h/hpl_blocked_partial_pivot_lu.nim)
- Odin: [`odin/h/hpl_blocked_partial_pivot_lu.odin`](../../../odin/h/hpl_blocked_partial_pivot_lu.odin)
- Rust: [`rust/h/hpl_blocked_partial_pivot_lu.rs`](../../../rust/h/hpl_blocked_partial_pivot_lu.rs)
- V: [`v/h/hpl_blocked_partial_pivot_lu.v`](../../../v/h/hpl_blocked_partial_pivot_lu.v)
- Zig: [`zig/h/hpl_blocked_partial_pivot_lu.zig`](../../../zig/h/hpl_blocked_partial_pivot_lu.zig)
