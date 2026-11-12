# Intersection of F2 vector spaces

For each case, return a basis for the intersection of two subspaces of
`GF(2)^30`. Vector addition is bitwise XOR. The implementation first builds a
triangular XOR basis for `V`, with a coefficient mask recording which input
vectors form each basis row. It reduces each `U` vector modulo `span(V)`, then
eliminates the resulting quotient-space vectors while tracking their `U` and
`V` coefficients. Every dependent quotient row yields a vector in both spans.
The collected intersection basis is converted to a unique reduced row-echelon
form (RREF).

## Contract

The [official Library Checker task](https://github.com/yosupo06/library-checker-problems/blob/master/linear_algebra/intersection_of_f2_vector_spaces/task.md)
contains `T` cases. Each case gives independent sequences `U` and `V`; the
required result is a basis for `span(U) intersect span(V)`. The
[official limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/linear_algebra/intersection_of_f2_vector_spaces/info.toml)
allow up to 100,000 cases, 30 vectors per side, and 30-bit vector values.

The bounded benchmark profile uses `1 <= T <= 4`, `0 <= n,m <= 8`, and
`0 <= vector < 2^30`. It encodes input as the signed 64-bit array
`[T,(n,U[n],m,V[m])...]`. Each input vector list must be linearly independent;
malformed or dependent input returns `-1`. The byte output concatenates one
block per case: `[k,w_0,...,w_(k-1)]`, with no extra case count. All values are
signed 64-bit little-endian words. A null or undersized output buffer returns
`-2` without writing. The maximum valid input is 73 values (74 parseable for
length-error checks), and the maximum output is 288 bytes.

The canonical basis uses the highest set bit as pivot, processes pivots from
bit 29 down to bit 0, clears each pivot bit from every other row, and emits
rows in descending pivot order. This makes equivalent bases byte-identical.

## Distinctness and oracle

The local binary matrix product and determinant packages perform different
matrix operations. Existing real-valued rank and Gaussian-elimination
benchmarks use different fields and contracts. No local package returns a
basis for the intersection of two XOR-spanned subspaces; this is a distinct
output operation, not merely a GF(2) rank or determinant kernel.

[`workload.json`](workload.json) covers empty spaces, a full overlap requiring
RREF reduction, a one-dimensional overlap, multiple cases, dependent input,
and output-buffer errors. The independent
[`benchmarks/intersection_of_f2_vector_spaces_oracle.py`](../../intersection_of_f2_vector_spaces_oracle.py)
enumerates each bounded span as a set of vectors, intersects the sets, and
canonicalizes that result independently of the coefficient-tracking
elimination used by the ports.

## Implementations

| Language | Port |
|---|---|
| C | [`c/l/intersection_of_f2_vector_spaces.c`](../../../c/l/intersection_of_f2_vector_spaces.c) |
| C3 | [`c3/l/intersection_of_f2_vector_spaces.c3`](../../../c3/l/intersection_of_f2_vector_spaces.c3) |
| C++ | [`cpp/l/intersection_of_f2_vector_spaces.cpp`](../../../cpp/l/intersection_of_f2_vector_spaces.cpp) |
| Elisa | [`elisa/l/intersection_of_f2_vector_spaces.elisa`](../../../elisa/l/intersection_of_f2_vector_spaces.elisa) |
| Mojo | [`mojo/l/intersection_of_f2_vector_spaces.mojo`](../../../mojo/l/intersection_of_f2_vector_spaces.mojo) |
| Nim | [`nim/l/intersection_of_f2_vector_spaces.nim`](../../../nim/l/intersection_of_f2_vector_spaces.nim) |
| Odin | [`odin/l/intersection_of_f2_vector_spaces.odin`](../../../odin/l/intersection_of_f2_vector_spaces.odin) |
| Rust | [`rust/l/intersection_of_f2_vector_spaces.rs`](../../../rust/l/intersection_of_f2_vector_spaces.rs) |
| V | [`v/l/intersection_of_f2_vector_spaces.v`](../../../v/l/intersection_of_f2_vector_spaces.v) |
| Zig | [`zig/l/intersection_of_f2_vector_spaces.zig`](../../../zig/l/intersection_of_f2_vector_spaces.zig) |
