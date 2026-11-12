# Hafnian of a matrix

Compute the hafnian of an even-order symmetric matrix with zero diagonal modulo
998244353. The hafnian sums the product of edge weights over every perfect
pairing of the matrix indices.

## Contract

The bounded ABI accepts `[N, row-major N-by-N matrix...]` for even `2 <= N <=
16`. Entries must be residues in `[0, 998244353)`, the matrix must be symmetric,
and its diagonal must be zero. The result is one signed 64-bit little-endian
residue. Invalid input returns `-1`; a null or short output buffer returns
`-2` without writing.

The ports use subset dynamic programming. For each even subset, choose its
smallest index and pair it with each remaining index, multiplying that matrix
entry by the result for the subset with both indices removed. This takes
`O(N 2^N)` time and `O(2^N)` memory. The local size limit is intentionally
bounded for a portable cross-language benchmark and is below the official
Library Checker maximum of 38.

## Distinctness and provenance

The repository has bipartite matching, perfect matching, and matrix determinant
packages, but none evaluates the weighted sum of all perfect pairings. This
operation is therefore distinct from maximum matching and determinant
computation.

Official contract: [Library Checker — Hafnian of Matrix](https://github.com/yosupo06/library-checker-problems/blob/master/linear_algebra/hafnian_of_matrix/task.md).
The implementation is clean-room and uses only the problem's high-level
definition and modulus.

[`workload.json`](workload.json) includes weighted and unweighted matrices,
the bounded maximum order, and malformed matrix and output-buffer cases. The
independent oracle recursively enumerates pair choices for the bounded input.

## Implementations

| Language | Port |
|---|---|
| C | [`c/l/hafnian_of_matrix.c`](../../../c/l/hafnian_of_matrix.c) |
| C3 | [`c3/l/hafnian_of_matrix.c3`](../../../c3/l/hafnian_of_matrix.c3) |
| C++ | [`cpp/l/hafnian_of_matrix.cpp`](../../../cpp/l/hafnian_of_matrix.cpp) |
| Elisa | [`elisa/l/hafnian_of_matrix.elisa`](../../../elisa/l/hafnian_of_matrix.elisa) |
| Nim | [`nim/l/hafnian_of_matrix.nim`](../../../nim/l/hafnian_of_matrix.nim) |
| Odin | [`odin/l/hafnian_of_matrix.odin`](../../../odin/l/hafnian_of_matrix.odin) |
| Rust | [`rust/l/hafnian_of_matrix.rs`](../../../rust/l/hafnian_of_matrix.rs) |
| V | [`v/l/hafnian_of_matrix.v`](../../../v/l/hafnian_of_matrix.v) |
| Zig | [`zig/l/hafnian_of_matrix.zig`](../../../zig/l/hafnian_of_matrix.zig) |
| Mojo | [`mojo/l/hafnian_of_matrix.mojo`](../../../mojo/l/hafnian_of_matrix.mojo) |
