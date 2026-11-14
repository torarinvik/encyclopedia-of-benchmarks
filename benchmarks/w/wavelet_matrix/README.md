# Wavelet matrix rank, quantile, and range counting

This draft builds a static wavelet matrix by stable-partitioning the entire
sequence at each bit level, storing level-wide prefix ranks and zero counts.
Queries remap their range boundaries through the level arrays. The existing
[`wavelet_tree`](../wavelet_tree/README.md) instead builds node-local value
partitions and prefix ranks. Both expose the same bounded query contract.

Input is `[n, values[n], q, (opcode,a,b,c,d)*q]`, with `1<=n<=64`,
`0<=q<=128`, and sequence values in `[-1000,1000]`. Opcode 0 counts value
`a` in inclusive prefix `[0,b]` (`b=-1` is empty). Opcode 1 returns the
zero-based `c`th smallest value in inclusive range `[a,b]`. Opcode 2 counts
values in inclusive value range `[c,d]` and position range `[a,b]`. Query
fields not used by an opcode are ignored, as in the wavelet-tree contract.
The result is the sum of each answer plus 1,000,001, weighted by its one-based
query index. Invalid input or a null input returns -1.

Values are offset by 1000 and represented in 11 bits. Construction takes
`O(11*n)` time and `O(11*n)` words for these explicitly stored prefix counts;
each query takes `O(11)` time. This profile is not a compressed-bitvector
implementation. The algorithm idea comes from Claude and Navarro's [*The
Wavelet Matrix*](https://users.dcc.uchile.cl/~gnavarro/ps/spire12.4.pdf)
(2012); code, contract adaptation, and references are independently written.

Ten language drafts, two references, workload cases, an inventory checker, and
scalar-suite integration are present. Verifier source specifies exhaustive
small sequences, prefix ranks, range queries, extreme values, maximum frames,
and null inputs. The Elisa
draft uses a bounded view and indexed arrays. Nothing has been compiled or run.

| Language | Draft source |
| --- | --- |
| C | [C](../../../c/w/wavelet_matrix.c) |
| C3 | [C3](../../../c3/w/wavelet_matrix.c3) |
| C++ | [C++](../../../cpp/w/wavelet_matrix.cpp) |
| Elisa | [Elisa](../../../elisa/w/wavelet_matrix.elisa) |
| Mojo | [Mojo](../../../mojo/w/wavelet_matrix.mojo) |
| Nim | [Nim](../../../nim/w/wavelet_matrix.nim) |
| Odin | [Odin](../../../odin/w/wavelet_matrix.odin) |
| Rust | [Rust](../../../rust/w/wavelet_matrix.rs) |
| V | [V](../../../v/w/wavelet_matrix.v) |
| Zig | [Zig](../../../zig/w/wavelet_matrix.zig) |
