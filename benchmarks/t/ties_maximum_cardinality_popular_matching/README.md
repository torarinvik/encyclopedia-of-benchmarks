# Tied-list maximum-cardinality popular matching

This profile computes the greatest number of real posts assigned in any
popular matching for a small one-sided market whose applicants may tie posts
at the same rank. Only applicants vote. Posts do not rank applicants. A
private last-resort post, placed below every listed post, makes each matching
applicant-complete.

## Contract

- Exported symbol: `ties_maximum_cardinality_popular_matching`; ABI:
  `i64_array_scalar`.
- Input is `[A,P,E,(applicant,post,rank)*E]`, with `1<=A,P<=4` and
  `A<=E<=A*P`. Applicant and post IDs are zero based. Every applicant must
  have at least one distinct applicant-post edge. Ranks are positive integers
  in `1..P`, contiguous within each applicant's list; equal ranks represent a
  tie. A valid input must contain at least one tied rank group.
- Applicant `a` has private last-resort post `P+a`, ranked below all listed
  posts. Last resorts only make the assignment complete and do not contribute
  to the result.
- The exact input length is `3+3E`; maximum valid and parseable lengths are
  51 and 52 signed 64-bit words. Invalid input returns `-1`.
- The result is the maximum number of real posts in a popular
  applicant-complete matching. Zero means no popular matching exists. The
  maximum result is 4; the ABI returns a scalar and has no output buffer.

## Algorithm profile

The primary follows the tied-list algorithm of Abraham, Irving, Kavitha, and
Mehlhorn. It builds a maximum matching on rank-one edges and labels the
first-choice graph's vertices even, odd, or unreachable using an alternating
forest rooted at every exposed applicant and post. Each applicant keeps all
rank-one choices and all highest-ranked posts that are even in this graph;
the private last resort is included only if it is among those highest-ranked
even choices. The algorithm deletes odd-to-odd and odd-to-unreachable edges
from this generalized reduced graph, then augments the rank-one matching in
the filtered graph to obtain a popular matching.

To maximize real-post cardinality, it removes all private last-resort edges
and augments the popular matching to maximum size in the remaining graph. It
then restores the last-resort edges and augments again until every applicant
is matched. The deterministic bounded profile uses ascending applicant and
post IDs in matching and forest traversals. Each maximum matching uses
repeated single-path DFS augmentations; this does not implement the paper's
Hopcroft–Karp batching or claim its `O(sqrt(n)m)` running time. The profile
returns only the number of real posts, so no particular optimal assignment
is part of the ABI.

The independent reference enumerates applicant-complete assignments over
every listed post and private last resort, then checks popularity directly by
comparing applicant votes against every other assignment. It does not use the
E/O/U partition, reduced graph, or augmentation theorem.

This is distinct from [`ranked_matching_popular_matching`](../../r/ranked_matching_popular_matching/README.md),
which uses the tied-list popularity characterization to return a
lexicographically selected popular assignment but does not maximize real-post
cardinality. It is also distinct from
[`maximum_cardinality_popular_matching`](../../m/maximum_cardinality_popular_matching/README.md),
which uses the strict-list first/second-choice graph, degree-one elimination,
and cycle matching.

## Provenance and rights

Primary source: Abraham, Irving, Kavitha, and Mehlhorn, “Popular
Matchings,” *SIAM Journal on Computing* 37(4), 2007,
[DOI 10.1137/06067328X](https://doi.org/10.1137/06067328X). The authors'
[hosted paper](https://eprints.gla.ac.uk/3494/1/abraham3494.pdf) describes the
same Section 3 tied-list maximum-cardinality procedure. The book crosswalk is
Kavitha Telikepalli, “Ranked Matching,”
[DOI 10.1007/978-1-4939-2864-4_331](https://doi.org/10.1007/978-1-4939-2864-4_331).
The hosted PDF is provided by permission for personal use and is not
redistributed. The bounded contract, references, workload, and ports are
clean-room implementations of the mathematical algorithm description; no
source code, example instances, figures, or prose are reused. See
[`RIGHTS.md`](RIGHTS.md).

## Package files

[Workload](workload.json) · [primary reference](primary_oracle.py) ·
[independent reference](independent_oracle.py) ·
[static inventory](verify_workload.py) · [rights](RIGHTS.md)

| Language | Port |
|---|---|
| C | [source](../../../c/t/ties_maximum_cardinality_popular_matching.c) |
| C3 | [source](../../../c3/t/ties_maximum_cardinality_popular_matching.c3) |
| C++ | [source](../../../cpp/t/ties_maximum_cardinality_popular_matching.cpp) |
| Elisa | [source](../../../elisa/t/ties_maximum_cardinality_popular_matching.elisa) |
| Mojo | [source](../../../mojo/t/ties_maximum_cardinality_popular_matching.mojo) |
| Nim | [source](../../../nim/t/ties_maximum_cardinality_popular_matching.nim) |
| Odin | [source](../../../odin/t/ties_maximum_cardinality_popular_matching.odin) |
| Rust | [source](../../../rust/t/ties_maximum_cardinality_popular_matching.rs) |
| V | [source](../../../v/t/ties_maximum_cardinality_popular_matching.v) |
| Zig | [source](../../../zig/t/ties_maximum_cardinality_popular_matching.zig) |

No programs, tests, checkers, builds, compilers, profilers, or benchmarks were
run while drafting this package.
