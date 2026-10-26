# Weighted popular matching

This package finds a maximum-cardinality weighted popular matching for a small
bipartite market. Each applicant has a positive vote weight and a complete
strict ranking of all items. An applicant who is unmatched is treated as
preferring any listed item to being unmatched. A matching is popular when no
other feasible matching has a strictly positive weighted vote margin against
it. Among popular matchings, the maximum-cardinality one is returned, with
lexicographically smallest applicant assignment as the tie-break.

Input is `[applicant_count,item_count,weights[n],rankings[n*m]]`, with both
counts at most four and rank rows being permutations of `0..m-1` (rank zero is
best). Output is `[found,cardinality,assignment[n]]`, where item IDs are
zero-based and `-1` means unmatched. If no popular matching exists, the output
is `[0,0,-1,...,-1]`. Values are little-endian signed i64. Invalid input
returns `-1`; null output or insufficient capacity returns `-2` without
writing.

The chapter's definition is weighted majority popularity. This package uses
exhaustive enumeration for a tiny complete-ranking profile; it does not claim
to implement the chapter's polynomial-time weighted-popularity algorithms,
and it excludes incomplete lists and preference ties.

Source: “Weighted Popular Matchings,” *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_477`](https://doi.org/10.1007/978-1-4939-2864-4_477).
The package is clean-room work; no textbook prose or code was copied.

## Ports

| Language | Port |
|---|---|
| C | `c/w/weighted_popular_matching.c` |
| C3 | `c3/w/weighted_popular_matching.c3` |
| C++ | `cpp/w/weighted_popular_matching.cpp` |
| Elisa | `elisa/w/weighted_popular_matching.elisa` |
| Nim | `nim/w/weighted_popular_matching.nim` |
| Odin | `odin/w/weighted_popular_matching.odin` |
| Rust | `rust/w/weighted_popular_matching.rs` |
| V | `v/w/weighted_popular_matching.v` |
| Zig | `zig/w/weighted_popular_matching.zig` |

Primary oracle: `benchmarks/weighted_popular_matching_oracle.py`.
Independent verifier oracle: `benchmarks/weighted_popular_matching_verifier_oracle.py`.
