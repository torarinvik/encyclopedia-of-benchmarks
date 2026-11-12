# Schreier–Sims permutation group benchmark

This benchmark builds a fixed-base stabilizer chain from a set of permutations.
It returns the generated group's order and answers membership queries for more
permutations. Permutations use zero-based images, and composition applies the
left operand first: `compose(p,q)[i] = q[p[i]]`.

## Bounded ABI

The exported C ABI is
`int64_t schreier_sims(const int64_t *input, size_t length, uint8_t *output, size_t capacity)`.
Input is `[N,M,Q]`, followed by `M` permutations of degree `N` and `Q` query
permutations. Each permutation is a list of `N` distinct integers in
`0..N-1`. The local profile uses `1<=N<=6`, `0<=M<=4`, and `1<=Q<=8`.

Malformed input returns `-1`. Valid input with a null output pointer or a
capacity below `8*(Q+1)` returns `-2` without writes. Success writes the group
order, then one `0` or `1` membership flag per query, as little-endian signed
64-bit integers. The maximum input is 75 words (76 parseable); maximum output
is 72 bytes.

The primary method keeps a stabilizer chain for the fixed base `0,1,...,N-1`.
It sifts each candidate through stored orbit transversals, inserts a residue
when it lies outside the represented subgroup, rebuilds that level's orbit,
and sends the resulting Schreier residues to the next stabilizer. This is an
incremental deterministic Schreier–Sims profile. With `B` independent strong
generator insertions, the bounded construction is `O(B^2 N^3)`; membership
queries take `O(N^3)` with the compact base-7 permutation encoding. Storage is
`O(NB)` apart from the bounded pending-residue queue.
Each layer holds at most 32 strong generators, and the pending queue holds at
most 8,192 Schreier residues. At degree six, each stabilizer can gain at most
nine independent generators; rebuilding a level enqueues at most 6 times 18
residues per insertion, so this fixed queue bound covers the bounded profile.

The independent oracle explicitly enumerates the generated group by closure
under the supplied generators and their inverses. Its degree bound limits the
closure to at most `6! = 720` permutations.

## Source and rights

Algorithm reference: [OI Wiki Schreier–Sims](https://oi-wiki.org/math/algebra/schreier-sims/).
OI Wiki identifies the article as CC BY-SA 4.0 and SATA; see [RIGHTS.md](RIGHTS.md).
The ports, bounded workload, oracles, and prose are clean-room.

Workload and package checker: [workload.json](workload.json) and
[verify_workload.py](verify_workload.py).

| Language | Source |
|---|---|
| C | [c/s/schreier_sims.c](../../../c/s/schreier_sims.c) |
| C3 | [c3/s/schreier_sims.c3](../../../c3/s/schreier_sims.c3) |
| C++ | [cpp/s/schreier_sims.cpp](../../../cpp/s/schreier_sims.cpp) |
| Elisa | [elisa/s/schreier_sims.elisa](../../../elisa/s/schreier_sims.elisa) |
| Mojo | [mojo/s/schreier_sims.mojo](../../../mojo/s/schreier_sims.mojo) |
| Nim | [nim/s/schreier_sims.nim](../../../nim/s/schreier_sims.nim) |
| Odin | [odin/s/schreier_sims.odin](../../../odin/s/schreier_sims.odin) |
| Rust | [rust/s/schreier_sims.rs](../../../rust/s/schreier_sims.rs) |
| V | [v/s/schreier_sims.v](../../../v/s/schreier_sims.v) |
| Zig | [zig/s/schreier_sims.zig](../../../zig/s/schreier_sims.zig) |
