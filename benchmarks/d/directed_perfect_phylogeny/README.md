# Directed perfect phylogeny for binary characters

This profile decides whether a binary character-state matrix admits a directed perfect phylogeny, using the chapter’s pairwise compatibility criterion. For every pair of characters, their sets of 1-valued taxa must be disjoint or one must contain the other. The output is a single signed 64-bit value: 1 when all pairs are compatible, otherwise 0. Tree reconstruction is outside this decision-only profile.

Input is `[taxa_count,character_count,matrix...]` in row-major order, with 1–12 taxa, 1–12 characters, and entries in `{0,1}`. Maximum input length is 146 words; output is 8 bytes. Invalid input returns `-1`; null or short output returns `-2` without writing.

## Implementations

| Language | Source |
|---|---|
| C | [`c/d/directed_perfect_phylogeny.c`](../../../c/directed_perfect_phylogeny.c) |
| C3 | [`c3/d/directed_perfect_phylogeny.c3`](../../../c3/directed_perfect_phylogeny.c3) |
| C++ | [`cpp/d/directed_perfect_phylogeny.cpp`](../../../cpp/directed_perfect_phylogeny.cpp) |
| Elisa | [`elisa/d/directed_perfect_phylogeny.elisa`](../../../elisa/d/directed_perfect_phylogeny.elisa) |
| Nim | [`nim/d/directed_perfect_phylogeny.nim`](../../../nim/d/directed_perfect_phylogeny.nim) |
| Odin | [`odin/d/directed_perfect_phylogeny.odin`](../../../odin/d/directed_perfect_phylogeny.odin) |
| Rust | [`rust/d/directed_perfect_phylogeny.rs`](../../../rust/d/directed_perfect_phylogeny.rs) |
| V | [`v/d/directed_perfect_phylogeny.v`](../../../v/d/directed_perfect_phylogeny.v) |
| Zig | [`zig/d/directed_perfect_phylogeny.zig`](../../../zig/d/directed_perfect_phylogeny.zig) |

Primary oracle: [`directed_perfect_phylogeny_oracle.py`](../../directed_perfect_phylogeny_oracle.py). Independent verifier: [`directed_perfect_phylogeny_verifier_oracle.py`](../../directed_perfect_phylogeny_verifier_oracle.py).

## Attribution and rights

Based on Jesper Jansson, “Directed Perfect Phylogeny (Binary Characters),” *Encyclopedia of Algorithms* (2016), DOI [10.1007/978-1-4939-2864-4_112](https://doi.org/10.1007/978-1-4939-2864-4_112). The ports implement the pairwise compatibility decision independently; no book prose, code, or figures are reproduced. The book remains copyrighted by Springer; attribution does not grant redistribution rights to its contents.
