# Rank-maximal matching by Irving's rank phases

This bounded profile computes the lexicographically maximum rank-count vector
for a bipartite applicant-post graph. Its objective differs from the
popular-matching profiles: it maximizes the number of rank-1 assignments,
then rank-2 assignments subject to that optimum, and continues in rank order.

## Contract

The exported `i64_array_bytes_output` symbol is
`rank_maximal_matching_irving`. Input is
`[A,P,E,(applicant,post,rank)*E]`, with `1<=A,P<=4`, at most 16 distinct edges,
and rank labels in `1..4`. Equal ranks encode tied choices; individual
applicants may omit rank levels. Every applicant must list at least one post.
Unmatched applicants are allowed and no private last-resort posts are added.
The valid and parseable input lengths are 51 and 52 words. Preference records
are normalized into a matrix, so their input order does not affect the result.

The output is `[R,s1,...,sR]` in little-endian signed i64, where `R` is the
highest supplied rank and `si` is the number of matched rank-i edges. Output
uses at most 40 bytes. Invalid input returns `-1`; null output or insufficient
capacity returns `-2` without writes. Workspace is bounded to 1,024 bytes.

The primary follows Irving's rank-phase reduction. At each phase it selects a
maximum matching in the surviving graph, classifies vertices as even, odd, or
unreachable by alternating paths rooted at all unmatched vertices, removes
active odd-odd and odd-unreachable edges, and permanently discards higher-rank
edges incident to odd or unreachable vertices. It then continues with the
next rank. Since this profile is bounded to four applicants and four posts,
each phase computes its maximum matching by enumerating the at most
`(P+1)^A` partial assignments and selecting a maximum-cardinality one. This
bounded subroutine changes the matching implementation cost while preserving
the phase reduction and rank-signature objective. If several maximum
matchings occur, the subroutine selects the lexicographically smallest
applicant assignment, with unmatched after all real post IDs. No matching
certificate is emitted, so this deterministic internal tie rule does not alter
the unique optimal signature in the output.

The independent oracle enumerates every valid partial matching of the input
graph and takes the lexicographically maximum signature directly, without
using the reduced-graph phases.

## Distinctness and provenance

The local [`ranked_matching_popular_matching`](../ranked_matching_popular_matching/README.md)
package implements a popularity characterization for lists with ties and
incomplete lists. Popularity compares pairwise votes between matchings;
rank-maximality optimizes the rank-count signature. The existing strict-list
and tied-list popular maximum-cardinality packages likewise optimize
popularity subject to maximum size, not rank-maximality.

The phase method is described by Telikepalli Kavitha, [“Ranked Matching,”
*Encyclopedia of Algorithms*, Chapter 331](https://doi.org/10.1007/978-1-4939-2864-4_331),
and R. W. Irving, T. Kavitha, K. Mehlhorn, D. Michail, and K. Paluch,
[“Rank-maximal matchings,” *ACM Transactions on Algorithms* 2(4), 602–610
(2006), §§2.2 and 2.4](https://doi.org/10.1145/1198513.1198520). The latter
sections define the even/odd/unreachable decomposition and rank-phase edge
reduction used here. Only the mathematical
method is used. Code, oracle formulations, fixtures, and explanatory text
are clean-room; no upstream code, book prose, or examples are copied. See
[`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json), the references,
and the static inventory.

The shared `i64_array_bytes_output` runner and verifier register the primary
and independent references, workspace and frame bounds, and all fixtures.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/r/rank_maximal_matching_irving.c`](../../../c/r/rank_maximal_matching_irving.c) |
| C3 | [`c3/r/rank_maximal_matching_irving.c3`](../../../c3/r/rank_maximal_matching_irving.c3) |
| C++ | [`cpp/r/rank_maximal_matching_irving.cpp`](../../../cpp/r/rank_maximal_matching_irving.cpp) |
| Elisa | [`elisa/r/rank_maximal_matching_irving.elisa`](../../../elisa/r/rank_maximal_matching_irving.elisa) |
| Mojo | [`mojo/r/rank_maximal_matching_irving.mojo`](../../../mojo/r/rank_maximal_matching_irving.mojo) |
| Nim | [`nim/r/rank_maximal_matching_irving.nim`](../../../nim/r/rank_maximal_matching_irving.nim) |
| Odin | [`odin/r/rank_maximal_matching_irving.odin`](../../../odin/r/rank_maximal_matching_irving.odin) |
| Rust | [`rust/r/rank_maximal_matching_irving.rs`](../../../rust/r/rank_maximal_matching_irving.rs) |
| V | [`v/r/rank_maximal_matching_irving.v`](../../../v/r/rank_maximal_matching_irving.v) |
| Zig | [`zig/r/rank_maximal_matching_irving.zig`](../../../zig/r/rank_maximal_matching_irving.zig) |
