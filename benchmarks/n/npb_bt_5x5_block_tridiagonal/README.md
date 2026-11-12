# NAS BT 5×5 block tridiagonal sweep

This package is a bounded profile of the block-line solve used by the BT kernel
in NASA's [NAS Parallel Benchmarks report RNR-94-007](https://www.nas.nasa.gov/assets/nas/pdf/techreports/1994/rnr-94-007.pdf),
pp. 63–64. A line is solved with the block Thomas recurrence: each row couples
five unknowns to the preceding and following five-component rows, and each
elimination stage solves a dense 5×5 system with six right-hand sides. The
final solution is recovered by block back-substitution.

The profile accepts one explicit block-tridiagonal line with 2 to 4 rows. Its
5×5 blocks are small integer matrices, which keeps the input bounded while
retaining both within-block coupling and cross-row coupling. The scalar result
is the one-based position-weighted sum of all solved unknowns. This profile
does not generate BT's CFD coefficients, perform its full explicit residual
calculation, or run the three approximate-factorization sweeps; it isolates
the repeated block-line solve described by the report.

## Contract

ABI: `i64_array_float64`; symbol: `npb_bt_5x5_block_tridiagonal`.

Input is `[N, row_0, ..., row_(N-1)]`, where each row contains, in order,
25 row-major lower-block entries, 25 diagonal-block entries, 25 upper-block
entries, and 5 right-hand-side values. Thus the exact length is `1 + 80*N`,
with `N` in `[2,4]`. The first lower block and final upper block must be zero.
Off-diagonal block entries and diagonal-block off-diagonal entries lie in
`[-2,2]`; diagonal-block diagonal entries lie in `[40,64]`; right-hand-side
entries lie in `[-1000,1000]`. Every scalar row must be strictly diagonally
dominant after including its lower and upper block entries. Invalid input
returns `-1e300`.

The result is `sum((q+1)*x[q])` over the flattened solution in block-row,
component order, with `q` starting at zero. Compare binary64 values with
absolute and relative tolerance `1e-10`. The bounded matrices keep the no-pivot
block recurrence nonsingular; each 5×5 block solve uses partial pivoting.

## Distinctness and provenance

RNR-94-007 describes independent nondiagonally dominant 5×5 block-tridiagonal
systems as a selected kernel, and its BT algorithm solves such systems in the
three coordinate directions as part of Beam–Warming approximate
factorization. The present bounded matrices use a stronger diagonal-dominance
precondition for a stable, portable profile, and the package deliberately
measures one line solve rather than claiming a complete BT benchmark.

Local [`thomas_algorithm`](../../t/thomas_algorithm/README.md) handles scalar
tridiagonal systems. Applying that scalar recurrence five times would omit the
within-row 5×5 coupling present here. [`polybench_adi`](../../p/polybench_adi/README.md)
is a two-dimensional scalar ADI workload; it does not solve 5×5 block lines.
The ports are clean-room implementations based on the report's algorithmic
description. No NASA implementation code or report prose is reproduced.

The primary block-Thomas oracle is
[`../../npb_bt_5x5_block_tridiagonal_oracle.py`](../../npb_bt_5x5_block_tridiagonal_oracle.py).
The independent oracle builds the full dense system and solves it over exact
rationals in
[`../../npb_bt_5x5_block_tridiagonal_verifier_oracle.py`](../../npb_bt_5x5_block_tridiagonal_verifier_oracle.py).
[`workload.json`](workload.json) records one hand-constructed coupled system
with known solution and malformed-frame cases. [`verify_workload.py`](verify_workload.py)
checks the package metadata, fixtures, and port inventory without compiling
or running any implementation.

## Rights

The algorithmic source is NASA Ames Research Center Technical Report
RNR-94-007, “The NAS Parallel Benchmarks.” These new files are independently
written from the mathematical block-tridiagonal recurrence described in the
report. No upstream benchmark source, comments, tables, or prose were copied.
See [`RIGHTS.md`](RIGHTS.md) for the scope of this provenance note.

## Language ports

| Language | Source |
|---|---|
| C | [`c/n/npb_bt_5x5_block_tridiagonal.c`](../../../c/n/npb_bt_5x5_block_tridiagonal.c) |
| C3 | [`c3/n/npb_bt_5x5_block_tridiagonal.c3`](../../../c3/n/npb_bt_5x5_block_tridiagonal.c3) |
| C++ | [`cpp/n/npb_bt_5x5_block_tridiagonal.cpp`](../../../cpp/n/npb_bt_5x5_block_tridiagonal.cpp) |
| Elisa | [`elisa/n/npb_bt_5x5_block_tridiagonal.elisa`](../../../elisa/n/npb_bt_5x5_block_tridiagonal.elisa) |
| Mojo | [`mojo/n/npb_bt_5x5_block_tridiagonal.mojo`](../../../mojo/n/npb_bt_5x5_block_tridiagonal.mojo) |
| Nim | [`nim/n/npb_bt_5x5_block_tridiagonal.nim`](../../../nim/n/npb_bt_5x5_block_tridiagonal.nim) |
| Odin | [`odin/n/npb_bt_5x5_block_tridiagonal.odin`](../../../odin/n/npb_bt_5x5_block_tridiagonal.odin) |
| Rust | [`rust/n/npb_bt_5x5_block_tridiagonal.rs`](../../../rust/n/npb_bt_5x5_block_tridiagonal.rs) |
| V | [`v/n/npb_bt_5x5_block_tridiagonal.v`](../../../v/n/npb_bt_5x5_block_tridiagonal.v) |
| Zig | [`zig/n/npb_bt_5x5_block_tridiagonal.zig`](../../../zig/n/npb_bt_5x5_block_tridiagonal.zig) |
