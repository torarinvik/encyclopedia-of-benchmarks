# Maximum-cardinality popular matching

This profile computes the greatest number of real posts assigned by any
popular matching in a small one-sided preference market. Applicants rank a
nonempty subset of posts strictly; posts are indifferent and do not vote. Each
applicant receives a private last-resort post below every real choice, so the
popular matching under consideration is applicant-complete.

## Contract

- Exported symbol: `maximum_cardinality_popular_matching`; ABI:
  `i64_array_scalar`.
- Input is `[A,P,L0,...,L(A-1),row0_posts...,row(A-1)_posts...]`, with
  `1<=A,P<=6`. Each list length is in `1..P`; each row contains distinct
  zero-based post IDs in best-to-worst order. Input order defines preference
  rank. Posts have no preference list and cast no vote.
- For applicant `a`, the private last resort has ID `P+a` and is ranked below
  all listed real posts. Last resorts are internal to the matching definition
  and do not contribute to the returned cardinality.
- The exact input length is `2+A+sum(Li)`. Maximum valid and parseable lengths
  are 44 and 45 signed 64-bit words. Invalid input returns `-1`.
- The result is the maximum number of real posts in a popular
  applicant-complete matching. Zero means no popular matching exists; a valid
  popular matching must cover at least one first-choice post.
- The maximum result is 6. The scalar output has no output buffer.

## Algorithm profile

For each applicant, let `f(a)` be the first listed post. Let `s(a)` be the
first listed post that is not anyone's first choice, or the applicant's
private last resort if there is no such real post. The reduced graph keeps
edges from each applicant to `f(a)` and `s(a)`. The first-choice posts are
called f-posts.

The primary follows the strict-list maximum-cardinality method in the cited
paper. Let A1 be applicants with a last resort as `s(a)`; all other applicants
form A2. It builds an applicant-complete A2 matching by forcing degree-one
posts and removing their unique applicant, then matches each remaining
2-regular component by alternating around its cycle. If fewer posts than A2
applicants remain, there is no popular matching. It then augments real reduced
edges from unmatched A1 applicants, assigns any remaining A1 applicant to
their private last resort, and promotes a lowest-ID first-choice applicant to
any still-unmatched f-post.

The independent reference enumerates each applicant's two permitted choices
`f(a)` and `s(a)`, rejects real-post collisions, and checks directly that every
f-post is covered. It maximizes the real-post count without using the primary's
degree-one reductions, cycle matching, or augmentation.

The tie refinements are deterministic: lowest post ID for degree-one
processing, lowest applicant/post IDs during traversal and promotion, and the
lower post ID for the first assignment in each residual cycle. The algorithmic
description is from Abraham, Irving, Kavitha, and Mehlhorn's strict-list
maximum-cardinality procedure; this bounded trace does not claim to be their
asymptotically optimized implementation.

This package is distinct from [`ranked_matching_popular_matching`](../../r/ranked_matching_popular_matching/README.md), which supports ties and returns a popular matching without maximizing its real-post cardinality. It also differs from [`weighted_popular_matching`](../../w/weighted_popular_matching/README.md), whose input gives both sides complete strict rankings and whose popularity definition uses weighted two-sided votes.

## Provenance and rights

Primary source: Abraham, Irving, Kavitha, and Mehlhorn, [“Popular Matchings”](https://doi.org/10.1137/06067328X), *SIAM Journal on Computing* 37(4), 2007. The chapter crosswalk is [“Ranked Matching”](https://doi.org/10.1007/978-1-4939-2864-4_331). The SIAM article retains its publisher copyright. The package uses algorithmic characterization and procedure descriptions only; the contract, fixtures, references, and ports are clean-room work. See [`RIGHTS.md`](RIGHTS.md).

## Files and ports

[Workload](workload.json) · [primary reference](primary_oracle.py) ·
[independent reference](independent_oracle.py) ·
[static inventory](verify_workload.py) · [rights](RIGHTS.md)

| Language | Port |
|---|---|
| C | [source](../../../c/m/maximum_cardinality_popular_matching.c) |
| C3 | [source](../../../c3/m/maximum_cardinality_popular_matching.c3) |
| C++ | [source](../../../cpp/m/maximum_cardinality_popular_matching.cpp) |
| Elisa | [source](../../../elisa/m/maximum_cardinality_popular_matching.elisa) |
| Mojo | [source](../../../mojo/m/maximum_cardinality_popular_matching.mojo) |
| Nim | [source](../../../nim/m/maximum_cardinality_popular_matching.nim) |
| Odin | [source](../../../odin/m/maximum_cardinality_popular_matching.odin) |
| Rust | [source](../../../rust/m/maximum_cardinality_popular_matching.rs) |
| V | [source](../../../v/m/maximum_cardinality_popular_matching.v) |
| Zig | [source](../../../zig/m/maximum_cardinality_popular_matching.zig) |

No programs, tests, checkers, builds, compilers, profilers, or benchmarks were
run while drafting this package.
