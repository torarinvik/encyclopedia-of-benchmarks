# Two-level dynamic maximal matching: insertion profile

This package isolates the fully specified insertion procedure of the
two-level maximal-matching algorithm in Chapter 567 of the *Encyclopedia of
Algorithms*. It starts with an empty graph and processes a bounded sequence
of edge insertions. Vertices begin at level 0. When a level-0 vertex reaches
the chapter threshold `sqrt(n)`, it is promoted with a uniformly selected
owned neighbor; the selected neighbor is promoted with it, and their previous
mates are repaired by scanning for free level-0 neighbors.

For reproducible calls, the input contains the random ranks explicitly. Each
rank selects an element of the currently sorted owned-neighbor list. This is
one supplied realization of the randomized process; it does not claim the
chapter's expected amortized update bound. The integer threshold is restricted
to `n=4` or `n=9`, so `sqrt(n)` is exact. To resolve choices left open in the
text, equal owned counts choose the lower vertex ID, and free-neighbor repairs
scan IDs increasingly.

## Contract

ABI: `i64_array_bytes_output`; symbol:
`two_level_dynamic_maximal_matching_insertions`.
Input is `[n,q,(u,v)[q],r,(rank)[r]]`, starting from an empty simple
undirected graph. `n` is 4 or 9, `0<=q<=24`, each insertion has `u<v`, and
duplicates are invalid. `r` must exactly equal the number of random mate
choices consumed. A supplied rank must be less than the current number of
owned neighbors at that choice. Maximum valid input is 55 signed 64-bit words.

Output is `[n, levels[n], partner[n]]`, each a little-endian signed 64-bit
word. A free vertex has partner `-1`. Maximum output is 19 words (152 bytes).
Malformed frames, invalid updates, or invalid random ranks return `-1` before
output checks. Null or short output returns `-2` without writes.

Deletion handling is excluded. The chapter's level-1 deletion description
does not specify repair of a selected neighbor's pre-existing mate, which may
be at either level; this package does not invent that rule. This insertion
profile is distinct from static Edmonds maximum-cardinality matching and from
the repository's bipartite matching packages.

## Source and rights

Source chapter: Surender Baswana, Manoj Gupta, and Sandeep Sen, “Matching in
Dynamic Graphs,” DOI
[`10.1007/978-1-4939-2864-4_567`](https://doi.org/10.1007/978-1-4939-2864-4_567).
Ports are independently written from the described update procedure and
contain no copied book text or code. See [`RIGHTS.md`](RIGHTS.md).

Primary oracle: [`two_level_dynamic_maximal_matching_insertions_oracle.py`](../../two_level_dynamic_maximal_matching_insertions_oracle.py).
Independent verifier: [`two_level_dynamic_maximal_matching_insertions_verifier_oracle.py`](../../two_level_dynamic_maximal_matching_insertions_verifier_oracle.py).
Fixtures: [`workload.json`](workload.json).

| Language | Port |
|---|---|
| C | `c/t/two_level_dynamic_maximal_matching_insertions.c` |
| C3 | `c3/t/two_level_dynamic_maximal_matching_insertions.c3` |
| C++ | `cpp/t/two_level_dynamic_maximal_matching_insertions.cpp` |
| Elisa | `elisa/t/two_level_dynamic_maximal_matching_insertions.elisa` |
| Nim | `nim/t/two_level_dynamic_maximal_matching_insertions.nim` |
| Odin | `odin/t/two_level_dynamic_maximal_matching_insertions.odin` |
| Rust | `rust/t/two_level_dynamic_maximal_matching_insertions.rs` |
| V | `v/t/two_level_dynamic_maximal_matching_insertions.v` |
| Zig | `zig/t/two_level_dynamic_maximal_matching_insertions.zig` |
