# Brzozowski DFA minimization

Return the number of states in the accessible minimal DFA equivalent to a
small, complete binary DFA. The primary method reverses the automaton and
determinizes its reachable subsets twice, following Brzozowski's minimization
theorem. It is distinct from [`hopcroft_dfa_minimization`](../hopcroft_dfa_minimization/README.md),
which computes equivalence classes by partition refinement.

The scalar input is `[N,start_state,accepting_mask,(next_on_0,next_on_1)*N]`.
`1<=N<=3`; state IDs are `0..N-1`, the start is in range, bit `i` of the
acceptance mask marks state `i`, and each state has one in-range destination
for both symbols. The maximum valid input is 9 i64 values and the parse bound
is 10. Malformed or null input returns `-1`.

In each reverse step, the old accepting states become the new initial subset,
the old initial state becomes the sole accepting state, and a transition's
destination subset is the set of old states whose matching transition enters
the current subset. Breadth-first subset construction assigns IDs in
discovery order. The first stage has at most 8 states; the second has at most
256. The scalar result is the second stage's reachable state count. This
bounded profile has an 8,192-byte workspace cap.

The largest fixed-array port reserves 2,616 bytes for transition, subset,
queue, and visited-state tables. The Mojo port's seven fixed-length lists hold
at most 558 machine integers (4,464 payload bytes); the 8,192-byte cap leaves
space for bounded list descriptors, alignment, and local state. Nim uses the
same bounded table lengths as the fixed-array ports.

The primary reference performs the two reverse/subset stages. The independent
reference marks states reachable from the original start and repeatedly
marks distinguishable state pairs until stable, then counts the remaining
equivalence classes. The workload includes empty and universal languages,
equivalent and unreachable states, and malformed frames.

NIST DADS's [finite state machine minimization entry](https://xlinux.nist.gov/dads/HTML/finitestmmin.html)
was used to discover the operation. The method follows Brzozowski's
“Canonical Regular Expressions and Minimal State Graphs for Definite Events,”
*Mathematical Theory of Automata* 12 (1962), 529–561; a concise statement of
the reverse/subset theorem appears in the
[Prague Stringology proceedings](https://psc.fit.cvut.cz/cgi-bin/getfile.cgi?c=-&n=11&t=pdf&y=2002).
Only algorithmic ideas were used; no code, examples, figures, or prose were
copied. See [RIGHTS.md](RIGHTS.md).

| Language | Port |
| --- | --- |
| C | [`c/b/brzozowski_dfa_minimization.c`](../../../c/b/brzozowski_dfa_minimization.c) |
| C3 | [`c3/b/brzozowski_dfa_minimization.c3`](../../../c3/b/brzozowski_dfa_minimization.c3) |
| C++ | [`cpp/b/brzozowski_dfa_minimization.cpp`](../../../cpp/b/brzozowski_dfa_minimization.cpp) |
| Elisa | [`elisa/b/brzozowski_dfa_minimization.elisa`](../../../elisa/b/brzozowski_dfa_minimization.elisa) |
| Mojo | [`mojo/b/brzozowski_dfa_minimization.mojo`](../../../mojo/b/brzozowski_dfa_minimization.mojo) |
| Nim | [`nim/b/brzozowski_dfa_minimization.nim`](../../../nim/b/brzozowski_dfa_minimization.nim) |
| Odin | [`odin/b/brzozowski_dfa_minimization.odin`](../../../odin/b/brzozowski_dfa_minimization.odin) |
| Rust | [`rust/b/brzozowski_dfa_minimization.rs`](../../../rust/b/brzozowski_dfa_minimization.rs) |
| V | [`v/b/brzozowski_dfa_minimization.v`](../../../v/b/brzozowski_dfa_minimization.v) |
| Zig | [`zig/b/brzozowski_dfa_minimization.zig`](../../../zig/b/brzozowski_dfa_minimization.zig) |

These are source-only drafts. No programs, tests, scripts, checkers, builds,
compilers, profilers, or benchmarks were run.
