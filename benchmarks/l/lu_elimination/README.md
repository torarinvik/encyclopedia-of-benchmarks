# LU elimination

This package covers the pinned C# `Lu.Eliminate` operation. It solves `A*x=b` by first computing the no-pivot Doolittle factors, then applying forward substitution through `L` and backward substitution through `U`. It is distinct from [`lu_decompose`](../lu_decompose/README.md), which returns the factors instead of solving for `x`.

## Contract

The ABI is `float64_slice_io`. Input is `[n, A_row_major..., b...]`, where `n` is an exact integer in `0..4`, `A` is an `n` by `n` row-major matrix with exact integer entries in `[-1,1]`, and `b` contains exactly `n` exact integer values in `[-8,8]`. Every diagonal pivot computed by the unpivoted Doolittle decomposition must be nonzero. The bounded domain keeps the solve finite and well-conditioned enough for comparison at absolute and relative tolerance `1e-12`.

For each row `i` in increasing order, the source computes the upper-factor row from left to right, sets `L[i,i]=1`, then computes the lower-factor column below the diagonal from top to bottom. It next solves `L*y=b` in increasing `i`, summing `y[j]*L[i,j]` for `j<i`. It solves `U*x=y` in decreasing `i`, summing `x[j]*U[i,j]` for `j=i..n-1`. The source's back-substitution sum includes the current term while `x[i]` is still zero; the bounded finite pivot makes that extra term zero. The output is `x` in row order.

The exact input length is `1+n*n+n`; the maximum valid length is 21 and one extra value is parseable for rejecting trailing data. Malformed framing, unsupported bounds, fractional values, a zero/nonfinite computed pivot, or a nonfinite solution returns `-1` before output checks. A null output pointer or capacity below `n` returns `-2` without writes. An empty `0` by `0` system is a valid no-op: a non-null output with zero capacity returns zero, while a null output pointer returns `-2`.

## Pinned source

- C# `Lu.Eliminate` and its `Decompose` helper at commit `96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c`: https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Numeric/Decomposition/LU.cs

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Oracle: [`lu_elimination_oracle.py`](../../lu_elimination_oracle.py)

## Ports

| Language | Port |
| --- | --- |
| C | [`c/l/lu_elimination.c`](../../../c/l/lu_elimination.c) |
| C3 | [`c3/l/lu_elimination.c3`](../../../c3/l/lu_elimination.c3) |
| C++ | [`cpp/l/lu_elimination.cpp`](../../../cpp/l/lu_elimination.cpp) |
| Elisa | [`elisa/l/lu_elimination.elisa`](../../../elisa/l/lu_elimination.elisa) |
| Nim | [`nim/l/lu_elimination.nim`](../../../nim/l/lu_elimination.nim) |
| Odin | [`odin/l/lu_elimination.odin`](../../../odin/l/lu_elimination.odin) |
| Rust | [`rust/l/lu_elimination.rs`](../../../rust/l/lu_elimination.rs) |
| V | [`v/l/lu_elimination.v`](../../../v/l/lu_elimination.v) |
| Zig | [`zig/l/lu_elimination.zig`](../../../zig/l/lu_elimination.zig) |
