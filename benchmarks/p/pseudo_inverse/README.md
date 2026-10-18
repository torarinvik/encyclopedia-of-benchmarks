# Pseudoinverse of a one-column matrix

This benchmark follows the pinned C# `PseudoInverse.PInv` method and its `ThinSvd.Decompose` dependency. Input is `[row_count, column_count, row-major matrix entries...]`; the bounded contract accepts `row_count` 1–4 and `column_count` exactly 1. Output is `[output_rows, output_columns, row-major pseudoinverse entries...]`, so a matrix shaped `m × 1` produces an output shaped `1 × m`.

The single-column domain makes the source helper's random one-dimensional starting vector only a sign; that sign cancels between the left and right singular vectors. The source's internal SVD cutoff is `1e-5`; values it removes are also below the PInv method's `1e-4` cutoff, so the observable result remains `[1,m]` followed by zeros. For singular value `s = sqrt(sum(x_i*x_i))`, PInv sets the reciprocal to zero only when `abs(s) < 1e-4`; at exactly `1e-4` it reciprocates. Thus, for `s >= 1e-4`, the output row is `x_i / s²`.

Entries must be integer-valued in `[-4,4]`. The zero vector is valid; every nonzero vector has singular value at least 1. This avoids the pinned SVD helper's low-magnitude iteration region: it scales `AᵀA v` by 100 but normalizes only when that product's magnitude exceeds `1e-5`, so smaller singular values can decay before `PInv` applies its own cutoff. `PInv` uses a strict `abs(s) < 1e-4` zeroing rule and reciprocates equality, though this bounded input domain does not exercise that threshold because its singular values are either zero or at least 1. Invalid framing, shapes, or entries return `-1`; null output or insufficient capacity returns `-2` without writes. Float comparisons use absolute and relative tolerance `1e-10`.

See the [workload](workload.json), [oracle](../../pseudo_inverse_oracle.py), pinned [C# PInv source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Numeric/Pseudoinverse/PseudoInverse.cs), and pinned [ThinSvd dependency](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Numeric/Decomposition/ThinSVD.cs).

## Ports

- [C](../../../c/p/pseudo_inverse.c)
- [C++](../../../cpp/p/pseudo_inverse.cpp)
- [C3](../../../c3/p/pseudo_inverse.c3)
- [Rust](../../../rust/p/pseudo_inverse.rs)
- [Elisa](../../../elisa/p/pseudo_inverse.elisa)
- [Nim](../../../nim/p/pseudo_inverse.nim)
- [Odin](../../../odin/p/pseudo_inverse.odin)
- [V](../../../v/p/pseudo_inverse.v)
- [Zig](../../../zig/p/pseudo_inverse.zig)
