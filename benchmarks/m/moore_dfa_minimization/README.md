# Moore DFA minimization

This package benchmarks Moore's iterative whole-partition refinement on a
complete deterministic finite automaton. The input is
`[n, alphabet, start_state, accepting_mask, transitions...]`, with
`1<=n<=8`, `1<=alphabet<=3`, and exactly `n*alphabet` state-major transition
destinations in `0..n-1`. The start state is validated but does not filter the
state set: every supplied state participates, including those unreachable
from the start. Bit `s` of `accepting_mask` marks state `s` as accepting.

The initial partition separates accepting from rejecting states. Each pass
refines a state by the tuple consisting of its current class followed by the
current classes of its destinations in symbol order. New class IDs are
assigned in ascending state order on first signature occurrence. A round is
counted only when the partition strictly changes; the final stable pass is not
counted. The packed scalar result is
`(class_count << 28) | (round_count << 24) | labels`, where `labels` stores
each canonical class ID in a 3-bit field at offset `3*state`. The valid and
parseable input limits are 28 and 29 i64 values. Malformed or null input
returns `-1`.

The Moore refinement primary takes O(n³·alphabet) time in this bounded profile:
for each strict round it linearly checks up to n earlier signatures for every
state. Its transition and label arrays use O(n·alphabet) workspace. The
independent table-filling reference propagates distinguishable state pairs in
synchronous waves, then derives canonical equivalence classes; its worst-case
time is O(n³·alphabet) and workspace O(n²). The native ports use the same
conservative 4,096-byte workspace ceiling.

The local [`hopcroft_dfa_minimization`](../../h/hopcroft_dfa_minimization/README.md)
uses smaller-half predecessor splitters, and
[`brzozowski_dfa_minimization`](../../b/brzozowski_dfa_minimization/README.md)
uses reverse/subset construction. They compute minimization by different
procedures; this package pins Moore's synchronous signature-refinement trace.

The algorithm is attributed to Edward F. Moore, “Gedanken-Experiments on
Sequential Machines,” *Automata Studies* (1956),
[DOI 10.1515/9781400882618-006](https://doi.org/10.1515/9781400882618-006).
NIST DADS's [finite-state-machine minimization entry](https://xlinux.nist.gov/dads/HTML/finitestmmin.html)
was used as a discovery index. No upstream code, text, example automata, or
tests were copied.

| Language | Port |
| --- | --- |
| C | [`c/m/moore_dfa_minimization.c`](../../../c/m/moore_dfa_minimization.c) |
| C3 | [`c3/m/moore_dfa_minimization.c3`](../../../c3/m/moore_dfa_minimization.c3) |
| C++ | [`cpp/m/moore_dfa_minimization.cpp`](../../../cpp/m/moore_dfa_minimization.cpp) |
| Elisa | [`elisa/m/moore_dfa_minimization.elisa`](../../../elisa/m/moore_dfa_minimization.elisa) |
| Mojo | [`mojo/m/moore_dfa_minimization.mojo`](../../../mojo/m/moore_dfa_minimization.mojo) |
| Nim | [`nim/m/moore_dfa_minimization.nim`](../../../nim/m/moore_dfa_minimization.nim) |
| Odin | [`odin/m/moore_dfa_minimization.odin`](../../../odin/m/moore_dfa_minimization.odin) |
| Rust | [`rust/m/moore_dfa_minimization.rs`](../../../rust/m/moore_dfa_minimization.rs) |
| V | [`v/m/moore_dfa_minimization.v`](../../../v/m/moore_dfa_minimization.v) |
| Zig | [`zig/m/moore_dfa_minimization.zig`](../../../zig/m/moore_dfa_minimization.zig) |

The package is registered in the shared `i64_array_scalar` runner and
verifier. No programs, tests, scripts, helpers, checkers, builds, compilers,
profilers, or benchmarks were run.
