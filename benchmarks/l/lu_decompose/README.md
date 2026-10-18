# LU decomposition

This benchmark covers the no-pivot Doolittle decomposition in the pinned C implementation, with the matching C++ and Julia routines as additional source references. It accepts a square matrix and returns its lower- and upper-triangular factors.

## Contract

The ABI is `float64_slice_io`. Input is `[dimension, matrix_row_major...]`. Dimension is an exact integer from 1 through 4; each finite matrix entry is an integer in `[-8,8]`. The decomposition does not pivot rows. Inputs are valid only when every computed diagonal pivot of `U` is nonzero.

For each row `i`, the source computes `U[i,j] = A[i,j] - sum(L[i,k]*U[k,j])` for columns `j >= i`, with `k` increasing from zero through `i-1`. It then sets `L[i,i]=1` and computes entries below the diagonal as `(A[j,i] - sum(L[j,k]*U[k,i])) / U[i,i]`, again accumulating `k` in increasing order. The output is the full row-major `L` matrix followed by the full row-major `U` matrix. Coordinates are small integers, so the bounded arithmetic stays finite; results are compared with absolute and relative tolerance `1e-12`.

The Julia routine's inner loops also visit the current index `i`. At that point the factor slot it reads is still zero, so it adds one zero term after the same nonzero terms; this does not change the bounded factor values. The C/C++ increasing-index loop is the canonical operation order for the workload.

Malformed framing, unsupported bounds, fractional entries, or a zero computed pivot returns `-1` before output checks. A null output buffer or capacity below `2*dimension*dimension` returns `-2` without writes.

## Pinned sources

- C `lu_decomposition`: https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/numerical_methods/lu_decompose.c
- C++ `lu_decomposition` header called by the source file: https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/numerical_methods/lu_decomposition.h
- C++-1 wrapper and matching `lu_decomposition` header: https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/numerical_methods/lu_decompose.cpp and https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/numerical_methods/lu_decomposition.h. The header uses the same no-pivot row-wise operation order and returns separate L/U factors.
- Julia `lu_decompose`: https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/matrix/lu_decompose.jl

The random-printing demos, determinant helper, pivoted decomposition variants, and solve operations are outside this workload.

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Oracle: [`lu_decompose_oracle.py`](../../lu_decompose_oracle.py)

## Ports

| Language | Source |
| --- | --- |
| C | [`c/l/lu_decompose.c`](../../../c/l/lu_decompose.c) |
| C3 | [`c3/l/lu_decompose.c3`](../../../c3/l/lu_decompose.c3) |
| C++ | [`cpp/l/lu_decompose.cpp`](../../../cpp/l/lu_decompose.cpp) |
| Elisa | [`elisa/l/lu_decompose.elisa`](../../../elisa/l/lu_decompose.elisa) |
| Nim | [`nim/l/lu_decompose.nim`](../../../nim/l/lu_decompose.nim) |
| Odin | [`odin/l/lu_decompose.odin`](../../../odin/l/lu_decompose.odin) |
| Rust | [`rust/l/lu_decompose.rs`](../../../rust/l/lu_decompose.rs) |
| V | [`v/l/lu_decompose.v`](../../../v/l/lu_decompose.v) |
| Zig | [`zig/l/lu_decompose.zig`](../../../zig/l/lu_decompose.zig) |
