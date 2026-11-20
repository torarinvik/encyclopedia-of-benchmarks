# Cipolla modular square root

Return the least nonnegative square root of `n` modulo an odd prime `p`, or
`-1` when `n` is a quadratic nonresidue. The input is exactly `[n,p]`, with
`0 <= n < p` and an odd prime modulus in `3..1,000,003`. Primality is a caller
precondition, matching the neighboring Tonelli–Shanks profile; ports check the
bounded residue and modulus fields but do not run a primality test. Zero maps
to zero, and a nonzero quadratic residue maps to the smaller of its two roots.

Cipolla searches for `t` such that `d=t²-n` is a quadratic nonresidue, then
works in the quadratic extension represented by pairs `a+b√d`. Binary
exponentiation computes `(t+√d)^((p+1)/2)`; the result lies in the base field
and its first component is a square root. The search makes at most `p`
Legendre-symbol checks and the extension-field exponentiation takes
`O(log p)` pair multiplications. Scratch use is constant.

This method has the same input and output problem as
[`tonelli_shanks`](../tonelli_shanks/README.md), but uses arithmetic in a
quadratic extension rather than the 2-adic subgroup updates. The 2024 review
of finite-field square-root algorithms compares Cipolla and Tonelli–Shanks as
distinct methods. The [University of Connecticut textbook chapter](https://alozano.clas.uconn.edu/wp-content/uploads/sites/490/2022/12/amstext35.pdf)
provides Cipolla's finite-field derivation. The Rosetta Code task index was
used only to discover the algorithm title. Contracts, fixtures, oracles, and
ports were authored independently; see [`RIGHTS.md`](RIGHTS.md).

The primary oracle uses pair exponentiation in the extension field. The
independent oracle scans candidate roots directly. Workload cases cover zero,
residues on both sides of the fast path, nonresidues, a large prime, invalid
domains, and malformed frames. Ports have not been compiled or executed.

| Language | Source |
|---|---|
| C | [c/c/cipolla_modular_square_root.c](../../../c/c/cipolla_modular_square_root.c) |
| C3 | [c3/c/cipolla_modular_square_root.c3](../../../c3/c/cipolla_modular_square_root.c3) |
| C++ | [cpp/c/cipolla_modular_square_root.cpp](../../../cpp/c/cipolla_modular_square_root.cpp) |
| Elisa | [elisa/c/cipolla_modular_square_root.elisa](../../../elisa/c/cipolla_modular_square_root.elisa) |
| Mojo | [mojo/c/cipolla_modular_square_root.mojo](../../../mojo/c/cipolla_modular_square_root.mojo) |
| Nim | [nim/c/cipolla_modular_square_root.nim](../../../nim/c/cipolla_modular_square_root.nim) |
| Odin | [odin/c/cipolla_modular_square_root.odin](../../../odin/c/cipolla_modular_square_root.odin) |
| Rust | [rust/c/cipolla_modular_square_root.rs](../../../rust/c/cipolla_modular_square_root.rs) |
| V | [v/c/cipolla_modular_square_root.v](../../../v/c/cipolla_modular_square_root.v) |
| Zig | [zig/c/cipolla_modular_square_root.zig](../../../zig/c/cipolla_modular_square_root.zig) |
