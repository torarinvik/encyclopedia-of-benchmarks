# Super-stable matching with ties and incomplete lists

This package implements the SUPER2 proposal/elimination algorithm for the
stable marriage problem with mutually acceptable incomplete lists and ties on
either side. It is distinct from
[`weak_stable_matching_ties_incomplete`](../../w/weak_stable_matching_ties_incomplete/README.md):
weak stability treats a pair as blocking only when both endpoints strictly
prefer each other, while super-stability treats indifference as enough for a
blocking pair.

## Contract

- ABI `i64_array_scalar`; symbol `super_stable_matching_ties_incomplete`.
- Input `[n, men_rank[n*n], women_rank[n*n]]`, with `1<=n<=4` and row-major
  preference matrices. Rank zero means unacceptable; a positive rank is a
  strict preference level, and equal ranks represent a tie.
- Acceptability must be mutual: a pair is present in both lists or neither.
  Each person's positive rank levels must be dense from 1 through that list's
  last rank. Exact input length is `1+2*n*n` (maximum 33 words; maximum
  parseable length 34). Null, malformed, or out-of-range input returns `-1`.
- If no super-stable matching exists, return `-2`. Otherwise return the
  assignment as an integer in base `n+1`: man 0 is the most-significant digit,
  followed by increasing man IDs; a digit `0..n-1` identifies the assigned
  woman, and digit `n` means unmatched. The output is the lexicographically
  least assignment vector among maximum matchings of the terminal engagement
  graph. Its maximum value is `5^4-1=624`.

## Algorithm and deterministic rules

The primary follows Algorithm SUPER2 (Figure 2) in Manlove's paper. The
reduced preference graph stores still-possible pairs, while the engagement
relation stores current proposals. A separate per-woman marker records whether
she has ever received a proposal for the algorithm's final rejection test. At
each step the lowest-ID free man with a nonempty reduced list proposes to every
woman tied at the head of that list. A pair can be proposed again if it survived
previous reductions and the man later becomes free. Each woman deletes every
strict successor of a proposer from her reduced list, breaking an engagement
when one exists. If she is multiply engaged, she breaks all engagements and
deletes all men in the tail tie of her current reduced list. The process ends
when every man is engaged or has an empty reduced list.

The terminal engagement graph is searched exhaustively for a maximum matching,
which is practical for `n<=4`. Ties among maximum matchings use the
lexicographically least assignment vector. If a woman who received a proposal
is unmatched in that maximum matching, the algorithm reports that no
super-stable matching exists; otherwise the matching is encoded as above.
Men, tied women, deletion scans, and matching choices use increasing IDs.

The independent reference does not replay proposal/elimination. It enumerates
all assignments, checks the matching constraints and the direct super-stability
condition for every mutually acceptable pair, then selects the maximum-size,
lexicographically least stable assignment.

## Source and complexity

The primary is based on Algorithm SUPER2 in David F. Manlove,
[*Stable Marriage with Ties and Unacceptable Partners*](https://www.dcs.gla.ac.uk/~davidm/pubs/6497.pdf),
University of Glasgow Technical Report TR-1999-29, Figure 2, Section 4. The
covered Encyclopedia chapter is Iwama and Miyazaki,
[*Stable Marriage with Ties and Incomplete Lists*](https://doi.org/10.1007/978-1-4939-2864-4_805).
Both are used for algorithm ideas only; code, fixtures, and documentation are
clean-room.

The bounded primary takes `O(n^4 + n*(n+1)^n)` time including exhaustive
maximum matching and `O(n^2)` space. The independent assignment enumerator
takes `O((n+1)^n*n^2)` time and `O(n^2+n)` space.

See [`workload.json`](workload.json), [`primary_oracle.py`](primary_oracle.py),
[`independent_oracle.py`](independent_oracle.py), and the static inventory
[`check_inventory.py`](check_inventory.py).

| Language | Source |
|---|---|
| C | [super_stable_matching_ties_incomplete.c](../../../c/s/super_stable_matching_ties_incomplete.c) |
| C3 | [super_stable_matching_ties_incomplete.c3](../../../c3/s/super_stable_matching_ties_incomplete.c3) |
| C++ | [super_stable_matching_ties_incomplete.cpp](../../../cpp/s/super_stable_matching_ties_incomplete.cpp) |
| Elisa | [super_stable_matching_ties_incomplete.elisa](../../../elisa/s/super_stable_matching_ties_incomplete.elisa) |
| Mojo | [super_stable_matching_ties_incomplete.mojo](../../../mojo/s/super_stable_matching_ties_incomplete.mojo) |
| Nim | [super_stable_matching_ties_incomplete.nim](../../../nim/s/super_stable_matching_ties_incomplete.nim) |
| Odin | [super_stable_matching_ties_incomplete.odin](../../../odin/s/super_stable_matching_ties_incomplete.odin) |
| Rust | [super_stable_matching_ties_incomplete.rs](../../../rust/s/super_stable_matching_ties_incomplete.rs) |
| V | [super_stable_matching_ties_incomplete.v](../../../v/s/super_stable_matching_ties_incomplete.v) |
| Zig | [super_stable_matching_ties_incomplete.zig](../../../zig/s/super_stable_matching_ties_incomplete.zig) |
