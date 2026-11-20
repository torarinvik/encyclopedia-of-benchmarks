# Mestre strict weighted popular matching

This profile decides whether a bounded one-sided market admits a weighted
popular matching. Applicants have positive integer vote weights and strict,
possibly incomplete rankings of real jobs. Jobs do not vote. Every applicant
also has a private last-resort job ranked below the listed jobs, so every
matching used in the popularity definition is applicant-complete.

Input is `[A,J,weights[A],lengths[A],rows...]`. Each `row` contains distinct
zero-based job IDs in best-to-worst order. The bounds are `1<=A<=4`,
`1<=J<=5`, weights `1..1000`, and list lengths `1..J`. Output is `1` if a
popular matching exists, `0` if none exists, and `-1` for an invalid frame.
The input length is exactly `2+2A+sum(lengths)`, at most 30 words; a 31-word
frame is parseable only to reject trailing data. The ABI is
`i64_array_scalar`.

## Method

The primary follows Mestre’s strict-list category pruning. It processes
distinct weights from highest to lowest. For each applicant it identifies
`f(x)`, the first listed job not already selected as a higher-weight
category’s f-job, and then `s(x)`, the first job outside the f-job sets for
its own or higher categories. The private last resort is appended before
these scans. Each f-job receives a minimum-promotion-cost label. The method
rejects a category when an earlier f-job can be freed for an applicant at a
cost below that applicant’s weight, prunes unsafe duplicate f-edges, and
prunes s-edges whose promotion cost is too low. It then removes s-edges that
point to any f-job and tests the remaining reduced graph for a matching that
covers every applicant.

This bounded implementation uses deterministic augmenting-path matching for
the final applicant-completeness test; the category labels and edge-pruning
rules are the benchmark’s primary algorithmic work. It does not emit a
matching certificate. The independent reference enumerates feasible complete
assignments and applies the weighted-vote definition directly, without
category labels or reduced-graph matching. With at most four applicants and
five real jobs, the oracle has at most 501 feasible assignments.

## Sources and duplicate comparison

Primary method: Julián Mestre, [“Weighted Popular Matchings,” arXiv:0707.0546v1,
Section 2 and Figure 2](https://arxiv.org/abs/0707.0546). The supporting
applicant-complete matching reduction is described by Abraham, Irving,
Kavitha, and Mehlhorn, [“Popular Matchings,” Section 2.2](https://doi.org/10.1137/06067328X).
The related encyclopedia entry is [DOI 477](https://doi.org/10.1007/978-1-4939-2864-4_477).
The sources are used for algorithm descriptions only; no implementation,
example instance, test, or prose is reused.

This is distinct from [`weighted_popular_matching`](../../w/weighted_popular_matching/README.md),
which exhaustively searches tiny complete strict applicant rankings. The two
profiles use the same one-sided weighted popularity objective, but this
package handles incomplete lists and implements Mestre’s category-label
pruning method instead of exhaustive search. It also differs from
[`maximum_cardinality_popular_matching`](../maximum_cardinality_popular_matching/README.md),
which has unweighted one-sided preferences and maximizes the real-job count,
and from the ranked-matching packages, which support ties. The scalar result
reports existence only.

## Package files

[Workload](workload.json) · [rights](RIGHTS.md) ·
[primary reference](primary_oracle.py) ·
[independent reference](independent_oracle.py) ·
[static workload review](verify_workload.py) ·
[static inventory](check_inventory.py) · [inventory record](INVENTORY.md)

The profile is registered in the shared `i64_array_scalar` runner and
verifier. Neither the dedicated package checks nor the shared suite has been
run.

| Language | Port |
|---|---|
| C | [source](../../../c/m/mestre_strict_weighted_popular_matching.c) |
| C3 | [source](../../../c3/m/mestre_strict_weighted_popular_matching.c3) |
| C++ | [source](../../../cpp/m/mestre_strict_weighted_popular_matching.cpp) |
| Elisa | [source](../../../elisa/m/mestre_strict_weighted_popular_matching.elisa) |
| Mojo | [source](../../../mojo/m/mestre_strict_weighted_popular_matching.mojo) |
| Nim | [source](../../../nim/m/mestre_strict_weighted_popular_matching.nim) |
| Odin | [source](../../../odin/m/mestre_strict_weighted_popular_matching.odin) |
| Rust | [source](../../../rust/m/mestre_strict_weighted_popular_matching.rs) |
| V | [source](../../../v/m/mestre_strict_weighted_popular_matching.v) |
| Zig | [source](../../../zig/m/mestre_strict_weighted_popular_matching.zig) |

The package is clean-room work. No executable checks have been run.
