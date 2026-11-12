# Thomas algorithm for tridiagonal systems

Solve a strictly diagonally dominant tridiagonal linear system with the Thomas
algorithm (also called the tridiagonal matrix algorithm, or TDMA). The solver
performs one forward elimination sweep and one backward substitution sweep,
using linear time and linear storage without constructing a dense matrix.

## Contract

Input is `[N, lower[N], diagonal[N], upper[N], rhs[N]]`, where
`1 <= N <= 32`; `lower[0]` and `upper[N-1]` are zero; off-diagonal entries
lie in `[-16, 16]`; diagonal entries lie in `[17, 64]`; each row satisfies
`diagonal[i] > |lower[i]| + |upper[i]|`; and right-hand-side entries lie in
`[-1000, 1000]`. Output is `N` IEEE-754 binary64 solution values in
little-endian byte order. Invalid input returns `-1`; null or undersized output
returns `-2` without writing. Strict diagonal dominance keeps the no-pivot
Thomas recurrence's pivots nonzero within this bounded profile.

The oracle solves the equivalent dense system with exact rational Gaussian
elimination and partial pivoting. The output validator independently checks
the tridiagonal residual.

## Distinctness and provenance

The existing [`gaussian_elimination`](../g/gaussian_elimination/README.md)
profile builds an `N x N` matrix and uses generic dense forward elimination and
back substitution. This package consumes only the three diagonals and uses the
linear tridiagonal recurrence; the storage and arithmetic work grow as `O(N)`
instead of the dense `O(N^2)` storage and `O(N^3)` elimination work. The method
is described in the [NPTEL notes on sparse direct solvers](https://archive.nptel.ac.in/content/storage2/courses/103101009/modules/module4/sec4/1.4.html)
and in the research guide [A Guide for Implementing Tridiagonal Solvers on
GPUs](https://impact.crhc.illinois.edu/shared/Papers/A%20guide%20for%20implementing%20tridiagonal%20solvers%20on%20GPUs.pdf).
The ports are clean-room implementations of the recurrence; no reference source
code or problem text was copied.

[`workload.json`](workload.json) contains small systems with exact known
solutions, a fractional solution, malformed inputs, and output-buffer cases.

## Implementations

| Language | Port |
|---|---|
| C | [`c/t/thomas_algorithm.c`](../../../c/t/thomas_algorithm.c) |
| C3 | [`c3/t/thomas_algorithm.c3`](../../../c3/t/thomas_algorithm.c3) |
| C++ | [`cpp/t/thomas_algorithm.cpp`](../../../cpp/t/thomas_algorithm.cpp) |
| Elisa | [`elisa/t/thomas_algorithm.elisa`](../../../elisa/t/thomas_algorithm.elisa) |
| Mojo | [`mojo/t/thomas_algorithm.mojo`](../../../mojo/t/thomas_algorithm.mojo) |
| Nim | [`nim/t/thomas_algorithm.nim`](../../../nim/t/thomas_algorithm.nim) |
| Odin | [`odin/t/thomas_algorithm.odin`](../../../odin/t/thomas_algorithm.odin) |
| Rust | [`rust/t/thomas_algorithm.rs`](../../../rust/t/thomas_algorithm.rs) |
| V | [`v/t/thomas_algorithm.v`](../../../v/t/thomas_algorithm.v) |
| Zig | [`zig/t/thomas_algorithm.zig`](../../../zig/t/thomas_algorithm.zig) |
