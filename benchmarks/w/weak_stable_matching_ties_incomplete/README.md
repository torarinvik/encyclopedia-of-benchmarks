# Weak Stable Matching with Ties and Incomplete Lists

This profile implements the chapter's proposal-based deferred-acceptance
algorithm for weakly stable matching in the stable-marriage model with ties
and incomplete preference lists. It uses an explicit deterministic
refinement to resolve choices that the chapter leaves arbitrary, while
retaining the chapter's weak-stability notion.

## Contract

The ABI is `i64_array_bytes_output`. Input is
`[n, men_rank[n*n], women_rank[n*n]]`, with each matrix in row-major order.
For the men's matrix, cell `(m,w)` gives the rank of woman `w` in man's list;
for the women's matrix, cell `(w,m)` gives man's rank in woman's list. Rank
zero means unacceptable and positive ranks 1–n mean acceptable; equal positive
ranks encode a tie. Acceptability is reciprocal in this profile: both sides
must list a pair or neither may list it. There are n participants on each
side, with 1≤n≤6.

Each man's tied choices are refined by ascending woman ID. Each woman's tied
choices are refined by ascending man ID. The algorithm repeatedly lets the
lowest-ID free man with an untried acceptable woman propose to his next choice.
A woman retains the proposer preferred by her refined order and rejects the
other. This is deferred acceptance on a strict refinement of the input lists;
the result is stable under that refinement and therefore weakly stable under
the original lists. Unmatched participants are implicit. Output is
`[pair_count,man_0,woman_0,...]`, with pairs sorted by man ID, using at most
104 bytes. Malformed input returns `-1`; null or insufficient output returns
`-2` without writes.

This profile is distinct from strict complete-list Gale–Shapley: it accepts
incomplete lists, represents indifference, and defines weak stability against
the original tied preferences. The deterministic refinement selects one
reproducible stable outcome but does not solve the chapter's MAX-SMTI objective.
It also does not implement strong/super-stability tests, randomized tie
handling, or the chapter's approximation algorithms.

The primary oracle runs the deterministic proposal process. The independent
verifier enumerates bounded matchings, filters for strict-refinement
stability and weak stability in the original lists, then selects the
men-optimal stable matching.

## Workload and ports

The [workload](workload.json) exercises tied ranks on both sides, incomplete
lists and unmatched participants, a maximum-size complete strict instance,
malformed rank/acceptability data, null buffers, and short output capacity.

| Language | Port |
| --- | --- |
| C | [`c/w/weak_stable_matching_ties_incomplete.c`](../../../c/w/weak_stable_matching_ties_incomplete.c) |
| C3 | [`c3/w/weak_stable_matching_ties_incomplete.c3`](../../../c3/w/weak_stable_matching_ties_incomplete.c3) |
| C++ | [`cpp/w/weak_stable_matching_ties_incomplete.cpp`](../../../cpp/w/weak_stable_matching_ties_incomplete.cpp) |
| Elisa | [`elisa/w/weak_stable_matching_ties_incomplete.elisa`](../../../elisa/w/weak_stable_matching_ties_incomplete.elisa) |
| Nim | [`nim/w/weak_stable_matching_ties_incomplete.nim`](../../../nim/w/weak_stable_matching_ties_incomplete.nim) |
| Odin | [`odin/w/weak_stable_matching_ties_incomplete.odin`](../../../odin/w/weak_stable_matching_ties_incomplete.odin) |
| Rust | [`rust/w/weak_stable_matching_ties_incomplete.rs`](../../../rust/w/weak_stable_matching_ties_incomplete.rs) |
| V | [`v/w/weak_stable_matching_ties_incomplete.v`](../../../v/w/weak_stable_matching_ties_incomplete.v) |
| Zig | [`zig/w/weak_stable_matching_ties_incomplete.zig`](../../../zig/w/weak_stable_matching_ties_incomplete.zig) |

Source and provenance are in [RIGHTS.md](RIGHTS.md); see the
[primary oracle](../../weak_stable_matching_ties_incomplete_oracle.py) and
[independent verifier](../../weak_stable_matching_ties_incomplete_verifier_oracle.py).
