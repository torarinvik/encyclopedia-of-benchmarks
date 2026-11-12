# Bounded NPB scalar pentadiagonal line solve

This package isolates the scalar pentadiagonal linear solve used by NAS
Parallel Benchmarks SP. NASA's RNR-94-007 describes the diagonal form of the
approximate-factorization algorithm as three coordinate sweeps. The block
pentadiagonal operators in that form reduce to independent scalar
pentadiagonal systems; the report gives the line matrix structure and
coefficients in Chapter 3, pp. 64–70 (especially p. 69). This package covers
one caller-supplied line system, solved with banded forward elimination and
back substitution. See the [NASA official RNR-94-007 report](https://www.nas.nasa.gov/assets/nas/pdf/techreports/1994/rnr-94-007.pdf).

The `float64_slice_io` input is `[N, lower2[N], lower1[N], diagonal[N],
upper1[N], upper2[N], rhs[N]]`, with `5 <= N <= 16`. The bands represent row
coefficients at offsets -2, -1, 0, +1, +2. Coefficients and right-hand sides
must be finite; band entries lie in [-2,2], diagonal entries in [5,16], and
right-hand-side entries in [-64,64]. Out-of-range boundary bands must be
zero. Every row has a positive diagonal dominance margin of at least 0.25,
which keeps the no-pivot elimination pivots nonzero under this bound. Output
is the complete binary64 solution vector, in the same order as the rows.
Invalid input returns `-1`; a null output or capacity smaller than `N`
returns `-2` without writing. Comparisons use 1e-9 absolute and relative
tolerances.

This is a bounded line-solve profile, not the full SP pseudo-application. It
does not construct SP's PDE coefficients, five-variable state, right-hand
sides, three coordinate sweep schedule, time steps, initialization, or
verification norms. The caller supplies one scalar system explicitly.

## Distinction from local solvers

[`thomas_algorithm`](../../t/thomas_algorithm/README.md) stores one lower and
one upper diagonal and uses the tridiagonal recurrence. This package handles
two subdiagonals and two superdiagonals with a different banded elimination
update. [`polybench_adi`](../../p/polybench_adi/README.md) is a 2-D heat
recurrence whose directional systems are tridiagonal. [`gaussian_elimination`](../../g/gaussian_elimination/README.md)
uses a dense general matrix representation and does not expose a
pentadiagonal band solver. The 5×5 block tridiagonal solver in the NPB BT
package is also a distinct block system. No local package found in this
inventory implements this scalar pentadiagonal operation.

The direct banded recurrence is in
[`npb_sp_pentadiagonal_oracle.py`](../../npb_sp_pentadiagonal_oracle.py).
The independent verifier constructs a dense exact-rational matrix and uses
pivoted elimination in
[`npb_sp_pentadiagonal_verifier_oracle.py`](../../npb_sp_pentadiagonal_verifier_oracle.py).
Fixtures and static package checks are listed in
[`workload.json`](workload.json) and [`verify_workload.py`](verify_workload.py).

## Ports

- C: [`c/n/npb_sp_pentadiagonal_line_solve.c`](../../../c/n/npb_sp_pentadiagonal_line_solve.c)
- C3: [`c3/n/npb_sp_pentadiagonal_line_solve.c3`](../../../c3/n/npb_sp_pentadiagonal_line_solve.c3)
- C++: [`cpp/n/npb_sp_pentadiagonal_line_solve.cpp`](../../../cpp/n/npb_sp_pentadiagonal_line_solve.cpp)
- Elisa: [`elisa/n/npb_sp_pentadiagonal_line_solve.elisa`](../../../elisa/n/npb_sp_pentadiagonal_line_solve.elisa)
- Mojo: [`mojo/n/npb_sp_pentadiagonal_line_solve.mojo`](../../../mojo/n/npb_sp_pentadiagonal_line_solve.mojo)
- Nim: [`nim/n/npb_sp_pentadiagonal_line_solve.nim`](../../../nim/n/npb_sp_pentadiagonal_line_solve.nim)
- Odin: [`odin/n/npb_sp_pentadiagonal_line_solve.odin`](../../../odin/n/npb_sp_pentadiagonal_line_solve.odin)
- Rust: [`rust/n/npb_sp_pentadiagonal_line_solve.rs`](../../../rust/n/npb_sp_pentadiagonal_line_solve.rs)
- V: [`v/n/npb_sp_pentadiagonal_line_solve.v`](../../../v/n/npb_sp_pentadiagonal_line_solve.v)
- Zig: [`zig/n/npb_sp_pentadiagonal_line_solve.zig`](../../../zig/n/npb_sp_pentadiagonal_line_solve.zig)
