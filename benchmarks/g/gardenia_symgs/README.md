# GARDENIA symmetric Gauss–Seidel

This package profiles GARDENIA's sparse SymGS row update at pinned
[`chenxuhao/gardenia`](https://github.com/chenxuhao/gardenia) commit
[`5894df11cf47f8839945edadff43dc79e260216d`](https://github.com/chenxuhao/gardenia/tree/5894df11cf47f8839945edadff43dc79e260216d).
The source host orders rows by graph-color class, performs one forward pass over
the classes, then one reverse pass. For a row `u`, it scans CSR entries in
stored order, accumulates `x[v] * A[u,v]` for off-diagonal entries, and assigns
`x[u] = (b[u] - sum) / A[u,u]` when the diagonal is nonzero.

## Contract

The `float64_slice_io` function accepts
`[n, nnz, color_count, order[n], color_offsets[color_count+1], rowptr[n+1], colind[nnz], values[nnz], x0[n], b[n]]`.
Bounds are `1<=n<=8`, `1<=color_count<=n`, and `1<=nnz<=64`. CSR rows are
strictly column-sorted, the matrix is exactly symmetric and strictly row
diagonally dominant, and each diagonal is positive. `order` is a vertex
permutation; offsets form nonempty contiguous color classes; no structural
off-diagonal edge joins vertices in the same class. Matrix, initial-vector,
and right-hand-side values are finite and bounded to `[-4,4]`.

The returned `n` binary64 values are the final `x`. The source defaults to
binary32 `ValueT`; this bounded portable profile uses binary64 while retaining
the row traversal and update order. It accepts explicit matrix, initial `x`,
and `b` values because the pinned host leaves its `weights` array uninitialized
(the random weight initialization is commented out). Input validation errors
return `-1`; null or undersized output returns `-2` without writing. Numeric
comparison uses `1e-12` absolute and relative tolerances.

## Source crosswalk

- `src/symgs/omp_base.cc::gauss_seidel` and `SymGSSolver` are the canonical
  source row update and forward/reverse color schedule.
- `src/symgs/verifier.cc::gs_serial` independently repeats the same schedule.
- This is distinct from local [`gauss_seidel_method`](../gauss_seidel_method/README.md),
  which visits a dense system once per forward coordinate sweep; from
  [`scimark2_sor`](../scimark2_sor/README.md), which applies a fixed-omega
  five-point grid relaxation; and from
  [`polybench_seidel_2d`](../polybench_seidel_2d/README.md), which updates a
  nine-point 2D stencil in one forward in-place sweep.

See [`workload.json`](workload.json) and the independent
[`oracle`](../../gardenia_symgs_oracle.py). The repository's MIT license is
retained in [`LICENSE.txt`](LICENSE.txt).

| Language | Source |
| --- | --- |
| C | [`c/g/gardenia_symgs.c`](../../../c/g/gardenia_symgs.c) |
| C3 | [`c3/g/gardenia_symgs.c3`](../../../c3/g/gardenia_symgs.c3) |
| C++ | [`cpp/g/gardenia_symgs.cpp`](../../../cpp/g/gardenia_symgs.cpp) |
| Elisa | [`elisa/g/gardenia_symgs.elisa`](../../../elisa/g/gardenia_symgs.elisa) |
| Nim | [`nim/g/gardenia_symgs.nim`](../../../nim/g/gardenia_symgs.nim) |
| Odin | [`odin/g/gardenia_symgs.odin`](../../../odin/g/gardenia_symgs.odin) |
| Rust | [`rust/g/gardenia_symgs.rs`](../../../rust/g/gardenia_symgs.rs) |
| V | [`v/g/gardenia_symgs.v`](../../../v/g/gardenia_symgs.v) |
| Zig | [`zig/g/gardenia_symgs.zig`](../../../zig/g/gardenia_symgs.zig) |
