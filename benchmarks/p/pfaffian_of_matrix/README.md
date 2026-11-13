# Pfaffian of an alternating matrix

Given an alternating matrix of order `2N` over `F_998244353`, return its
Pfaffian modulo `998244353`. The bounded benchmark accepts `1<=N<=8`, so the
largest matrix has order 16. Entries must be canonical residues, diagonal
entries must be zero, and `A[j][i] = -A[i][j] mod 998244353`.

The primary algorithm performs pivoted Pfaffian elimination in `O((2N)^3)`
field operations and `O((2N)^2)` storage. It searches each active row for a
nonzero pivot partner; swapping an index pair changes the Pfaffian sign. A
Schur-complement update reduces the remaining alternating matrix. If the
active pivot row has no partner, the Pfaffian is zero.

The independent oracle uses a pairing-mask recurrence. It fixes the first
unpaired index and sums over each possible partner with alternating signs,
memoizing the result for each subset. Its `O(d*2^d)` work at `d=2N` is
structurally different from cubic elimination.

This is distinct from [`hafnian_of_matrix`](../../l/hafnian_of_matrix/README.md),
which sums matching products without signs, and from determinant benchmarks,
which compute a different matrix invariant. The official Library Checker task
allows `1<=N<=300`; this package deliberately uses a small profile suitable for
ten-language comparison.

The discovery source is [Library Checker — Pfaffian of Matrix](https://github.com/yosupo06/library-checker-problems/blob/master/linear_algebra/pfaffian_of_matrix/task.md)
with [official limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/linear_algebra/pfaffian_of_matrix/info.toml).
The upstream repository is Apache-2.0. This package uses the mathematical
contract and algorithm description only; the implementations and workload are
clean-room. See [`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json),
the two oracle modules, and the package-local static checker.

| Language | Port |
|---|---|
| C | [`c/p/pfaffian_of_matrix.c`](../../../c/p/pfaffian_of_matrix.c) |
| C3 | [`c3/p/pfaffian_of_matrix.c3`](../../../c3/p/pfaffian_of_matrix.c3) |
| C++ | [`cpp/p/pfaffian_of_matrix.cpp`](../../../cpp/p/pfaffian_of_matrix.cpp) |
| Elisa | [`elisa/p/pfaffian_of_matrix.elisa`](../../../elisa/p/pfaffian_of_matrix.elisa) |
| Mojo | [`mojo/p/pfaffian_of_matrix.mojo`](../../../mojo/p/pfaffian_of_matrix.mojo) |
| Nim | [`nim/p/pfaffian_of_matrix.nim`](../../../nim/p/pfaffian_of_matrix.nim) |
| Odin | [`odin/p/pfaffian_of_matrix.odin`](../../../odin/p/pfaffian_of_matrix.odin) |
| Rust | [`rust/p/pfaffian_of_matrix.rs`](../../../rust/p/pfaffian_of_matrix.rs) |
| V | [`v/p/pfaffian_of_matrix.v`](../../../v/p/pfaffian_of_matrix.v) |
| Zig | [`zig/p/pfaffian_of_matrix.zig`](../../../zig/p/pfaffian_of_matrix.zig) |
