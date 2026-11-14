# Hopcroft DFA minimization

Compute the number of language-equivalence classes of the states of a complete
deterministic finite automaton. Every supplied state is considered as a
possible start state; unreachable states are therefore not discarded. This is
distinct from [`string_match_finite_automata`](../../s/string_match_finite_automata/README.md),
which builds and runs a pattern matcher, and from
[`hopcroft_karp_cardinality`](../../h/hopcroft_karp_cardinality/README.md),
which computes a bipartite matching.

The proposed `i64_array_scalar` input is `[n, alphabet, accepting..., transitions...]`.
There are `1 <= n <= 4096` states and `1 <= alphabet <= 4` symbols. The next
`n` values are 0/1 acceptance flags, followed by `n*alphabet` transition
destinations in state-major order, each in `0..n-1`. Return the number of
equivalence classes, or -1 for invalid framing or values.

The benchmark maintains blocks of equivalent candidates, uses reverse
transition lists, and splits blocks by predecessor sets. Smaller-half splitter
scheduling gives O(alphabet*n*log n) time and O(alphabet*n) space. The
independent reference repeatedly refines signatures and is intended for small
cases. A complete transition table is an explicit profile choice; this does
not claim to reproduce all output conventions in the source proposal.

The [Library Checker proposal](https://github.com/yosupo06/library-checker-problems/issues/1387)
is an idea index. The bounded contract, code, reference, and prose are
independently authored; no upstream text, examples, tests, or code are copied.

Reserved and in progress: ten language drafts, an independent reference,
initial fixtures, a workload validator and scalar-suite registration are present.
The verifier specifies exhaustive small automata, compares signature refinement
with an independent pair-distinguishability reference, and includes known
maximum-size cases.
Static review releases temporary predecessor groups after each splitter and
reclaims partition buffers after geometric shrinkage, bounding retained
storage with amortized copying. Nothing has been compiled or run.
