# BDD symbolic reachability

This benchmark computes the states reachable in a small finite transition
system using reduced ordered binary decision diagrams (ROBDDs). It constructs
the transition relation from a supplied truth table, repeatedly takes a
relational product with the reached set, existentially removes current-state
and input variables, renames next-state variables, and unions newly reached
states until the BDD root reaches a fixed point.

## Contract

- ABI: `int64_t bdd_symbolic_reachability(const int64_t *input, size_t length)`.
- Input frame: `[n, m, initial_mask, invariant_mask, T...]`.
- `n` is 1 through 3 state bits; `m` is 0 or 1 input bits.
- The relation has `2^(2*n+m)` entries. Variable order is current-state bits,
  input bits, and next-state bits, with each bit vector read most-significant
  bit first. Entry index is `((state * 2^m + input) * 2^n + next_state)`.
- The exact valid frame length is `4 + 2^(2*n+m)`. The maximum valid frame is
  132 words; one extra word is parseable so trailing data can be rejected.
- Bit `s` of `initial_mask` marks an initial state. Bit `s` of
  `invariant_mask` marks a state satisfying the invariant.
- The scalar result is `(reachable_mask << 1) | violation`, where bit 0 is 1
  iff any reachable state violates the invariant. Invalid or null input returns
  `-1`.

The transition relation is represented as an ROBDD with fixed variable order,
unique-node reduction, and terminal IDs 0 and 1. Relational image is computed
as `exists(current,input, reached AND T)`, followed by next-to-current variable
renaming. Reachability is monotone over at most eight states, so the bounded
fixed point stabilizes after at most nine rounds.

The profile is distinct from [`binary_decision_graph`](../binary_decision_graph/README.md),
which only reduces a supplied Boolean truth table and reports the resulting
graph. This package uses BDDs to perform state-set reachability and invariant
checking; its independent reference enumerates transitions explicitly.

The native manager has a 288 KiB workspace ceiling. The largest fixed array
set uses 218,536 raw bytes: 17,000 variable bytes, four 17,000-entry `u16`
arrays for low/high children and existential/rename results, and a
32,768-entry `u16` unique table. Five ports omit the two transform-result
arrays and use 150,536 bytes. The remaining allowance covers bounded
recursion locals and stack frames. Each fixed-point round resets node
allocation to the retained relation prefix and rebuilds the unique table from
that prefix; ports with transform-result arrays clear them as well. Binary
apply uses recursive Shannon expansion without an operation memo table. With
at most seven variables, recursive paths use at most eight frames and the
deepest nested existential/apply path at most sixteen. A conservative
per-round node count is `127 + 7 + 127 + 127 + (127 * 127) + 7 + 7 = 16,531`:
the relation, reached set, conjunction, existential results and quantified
OR applications, renaming, and final union. This stays below the 17,000-node
cap. The reference implementations are
`primary_oracle.py` (ROBDD relational product) and `independent_oracle.py`
(explicit-state reachability).

## Sources and rights

The problem context and BDD-based verification method are described in
Aziz and Prakash, “Symbolic Model Checking,” Chapter 416 of the
[*Encyclopedia of Algorithms*](https://doi.org/10.1007/978-1-4939-2864-4_416).
The ROBDD representation is also covered by their [Binary Decision Graph
chapter](https://doi.org/10.1007/978-1-4939-2864-4_48). These sources supplied
algorithm descriptions only. The transition-table contract, bounded workload,
references, and ports were written independently; no book prose, code, figures,
or examples are reproduced.

## Language ports

| Language | Source |
|---|---|
| C | [`c/b/bdd_symbolic_reachability.c`](../../../c/b/bdd_symbolic_reachability.c) |
| C3 | [`c3/b/bdd_symbolic_reachability.c3`](../../../c3/b/bdd_symbolic_reachability.c3) |
| C++ | [`cpp/b/bdd_symbolic_reachability.cpp`](../../../cpp/b/bdd_symbolic_reachability.cpp) |
| Elisa | [`elisa/b/bdd_symbolic_reachability.elisa`](../../../elisa/b/bdd_symbolic_reachability.elisa) |
| Mojo | [`mojo/b/bdd_symbolic_reachability.mojo`](../../../mojo/b/bdd_symbolic_reachability.mojo) |
| Nim | [`nim/b/bdd_symbolic_reachability.nim`](../../../nim/b/bdd_symbolic_reachability.nim) |
| Odin | [`odin/b/bdd_symbolic_reachability.odin`](../../../odin/b/bdd_symbolic_reachability.odin) |
| Rust | [`rust/b/bdd_symbolic_reachability.rs`](../../../rust/b/bdd_symbolic_reachability.rs) |
| V | [`v/b/bdd_symbolic_reachability.v`](../../../v/b/bdd_symbolic_reachability.v) |
| Zig | [`zig/b/bdd_symbolic_reachability.zig`](../../../zig/b/bdd_symbolic_reachability.zig) |

`workload.json` defines bounded fixtures and malformed frames. The package
validators are source-only helpers; they have not been run.
