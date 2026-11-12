# Disjoint sparse table affine composition

This benchmark builds a static disjoint sparse table over affine maps and answers ordered range-composition queries. It uses the divide-at-the-highest-differing-bit construction described by the [CP-Algorithms sparse table article](https://cp-algorithms.com/data_structures/sparse-table.html) and the [OI Wiki Cat Tree article](https://oiwiki.net/ds/cat-tree/).

## Contract

Input is `[N,Q,(a,b)*N,(left,right)*Q]`. Each map denotes `f(x)=a*x+b` over the field modulo `1,000,000,007`. Bounds are `1<=N<=32`, `1<=Q<=32`, and `0<=a,b<MOD`. Queries are nonempty inclusive ranges with `0<=left<=right<N`. The exact input length is `2+2N+2Q`, at most 130 signed 64-bit words.

For each range, apply its maps from left to right: first `f_left`, then `f_(left+1)`, continuing through `f_right`. Return the resulting pair `(A,B)` where the composed map is `A*x+B mod MOD`. Output is two little-endian signed 64-bit words per query, at most 512 bytes. Malformed or null input returns `-1`; valid input with null output or insufficient capacity returns `-2` without writes; success returns the number of bytes written.

The primary implementation precomputes suffix and prefix folds around each power-of-two split. A query crossing a split combines exactly two disjoint folds selected by the highest set bit of `left XOR right`; singleton queries return their original map. Build complexity is `O(N log N)`, and each query uses `O(1)` combines. The independent oracle simulates each range twice, at inputs zero and one, then recovers `(A,B)`; it does not build the table.

## Provenance and rights

CP-Algorithms identifies the disjoint sparse table as an alternative for associative range operations that ordinary overlapping sparse tables cannot handle. OI Wiki's Cat Tree article describes the corresponding static split-and-fold structure. The CP-Algorithms site uses CC BY-SA 4.0; OI Wiki lists CC BY-SA 4.0 and SATA terms. This package uses algorithm descriptions only. All code, ABI details, and fixtures are clean-room work; see [`RIGHTS.md`](RIGHTS.md).

## Language ports

- [C](../../../c/d/disjoint_sparse_table_affine_composition.c)
- [C3](../../../c3/d/disjoint_sparse_table_affine_composition.c3)
- [C++](../../../cpp/d/disjoint_sparse_table_affine_composition.cpp)
- [Elisa](../../../elisa/d/disjoint_sparse_table_affine_composition.elisa)
- [Mojo](../../../mojo/d/disjoint_sparse_table_affine_composition.mojo)
- [Nim](../../../nim/d/disjoint_sparse_table_affine_composition.nim)
- [Odin](../../../odin/d/disjoint_sparse_table_affine_composition.odin)
- [Rust](../../../rust/d/disjoint_sparse_table_affine_composition.rs)
- [V](../../../v/d/disjoint_sparse_table_affine_composition.v)
- [Zig](../../../zig/d/disjoint_sparse_table_affine_composition.zig)

Fixtures are in [`workload.json`](workload.json). The package-local static inventory checker is [`verify_disjoint_sparse_table_affine_composition_package.py`](verify_disjoint_sparse_table_affine_composition_package.py).
