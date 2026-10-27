# Ranked popular matching

This bounded profile implements the chapter's applicant-ranked popular-matching
characterization for bipartite markets with ties and incomplete preference
lists. Each applicant's ranked posts are represented by positive rank numbers
with no gaps. The profile adds one private last-resort post below that
applicant's lowest listed rank.

Input is `[applicant_count,post_count,edge_count,(applicant,post,rank)*]`.
Applicant and post IDs are zero-based; ranks start at 1, and equal ranks encode
a tie. Counts are at most four and there are at most 16 distinct ranked edges.
Every applicant must list at least one post. The largest valid input has 51
i64 values.

The solver finds a maximum matching `M1` of the rank-one graph, labels vertices
even, odd, or unreachable by an alternating forest rooted at all unmatched
vertices on both sides, and treats isolated private last resorts as even. For
each applicant, `f(a)` is its set of rank-one posts and `s(a)` is the set of
most-preferred posts in its list whose vertices are even, considering its
private last resort at the appended rank. The reduced graph contains `f(a)`
and `s(a)` edges, then removes odd–odd and odd–unreachable edges. A profile
returns a popular matching exactly when a matching in that filtered reduced
graph covers every applicant and its rank-one edges have cardinality
`|M1|`. Covering applicants does not require using every private last resort:
an applicant's last-resort edge is present only when that post belongs to
`s(a)`.

For deterministic output, the bounded implementation exhaustively checks the
small characterization and returns the lexicographically smallest valid
applicant assignment, with real post IDs before private last-resort IDs. This
preserves the chapter's popularity criterion; it does not claim the chapter's
polynomial-time matching implementation. Output is
`[found,assignment_by_applicant]`, encoded as little-endian signed i64 values.
Real posts use IDs `0..post_count-1`; applicant `a`'s private last resort is
`post_count+a`. If no popular matching exists, output is `[0,-1,...,-1]`.
Invalid input returns `-1`; null output or capacity below `8*(applicant_count+1)`
returns `-2` without writing.

Source: “Ranked Matching,” Kavitha Telikepalli, *Encyclopedia of Algorithms*,
DOI [`10.1007/978-1-4939-2864-4_331`](https://doi.org/10.1007/978-1-4939-2864-4_331).
This clean-room profile does not copy book prose or source code. It differs
from stable matching and from weighted-majority popularity on complete strict
rankings.

Primary oracle: `benchmarks/ranked_matching_popular_matching_oracle.py`.
Independent verifier: `benchmarks/ranked_matching_popular_matching_verifier_oracle.py`.

| Language | Port |
|---|---|
| C | `c/r/ranked_matching_popular_matching.c` |
| C3 | `c3/r/ranked_matching_popular_matching.c3` |
| C++ | `cpp/r/ranked_matching_popular_matching.cpp` |
| Elisa | `elisa/r/ranked_matching_popular_matching.elisa` |
| Nim | `nim/r/ranked_matching_popular_matching.nim` |
| Odin | `odin/r/ranked_matching_popular_matching.odin` |
| Rust | `rust/r/ranked_matching_popular_matching.rs` |
| V | `v/r/ranked_matching_popular_matching.v` |
| Zig | `zig/r/ranked_matching_popular_matching.zig` |
