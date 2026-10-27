# Procedure S for general CNF satisfiability

This package implements a bounded profile of Procedure S described in “Exact Algorithms for General CNF SAT,” *Encyclopedia of Algorithms*, DOI [`10.1007/978-1-4939-2864-4_133`](https://doi.org/10.1007/978-1-4939-2864-4_133). The implementation preserves the chapter's outer clause-shortening recurrence and source-order branching. It uses exhaustive truth-table enumeration as a bounded replacement for the cited exact k-CNF subroutine; it does not claim the chapter's running-time bound.

## Contract

- ABI: `i64_array_bytes_output`. Input is `[n,m,k,(clause_length,literal...)*]`.
- Bounds: `1 <= n <= 5`, `0 <= m <= 6`, `1 <= k <= n`; each input clause has 1 through n literals, and no variable occurs more than once in a clause. The maximum valid input length is 39 words.
- A signed one-based literal `v` means variable `x_v`; a negative literal means its negation. Literals and clauses retain input order.
- At each Procedure S call, form `F'` by replacing every clause with its first `min(k, clause_length)` literals. The bounded exact subroutine enumerates complete assignments in lexicographic false-before-true order, with `x_1` first, and tests `F'` under the current fixed assignments. If it finds a model, it returns that model.
- If `F'` is unsatisfiable, visit clauses in input order. For clause `i`, falsify all literals in its shortened prefix `D_i`; in the child formula shorten each earlier clause to its prefix, keep clause `i` and later clauses full, and simplify under the new assignments. Recurse before trying the next clause. Conflicting or non-progressing prefixes are counted as branch attempts and skipped. Earlier recursion removes fixed variables from retained clauses, so a compatible nonempty prefix adds at least one variable and creates a child call.
- Output is six little-endian signed-i64 words: `[satisfiable, assignment_mask, calls, exact_checks, branch_attempts, maximum_depth]`. Bit `v-1` of `assignment_mask` is the value of `x_v`; zero is false and one is true. `calls` and `exact_checks` count Procedure S invocations; `branch_attempts` counts each clause considered at an unsatisfiable node, including skipped conflicts; root depth is zero. Maximum output is 48 bytes.
- Invalid input returns `-1`; null output or capacity below 48 returns `-2`, without writing output. The profile is deterministic and bounded; no claim is made for the cited algorithm's asymptotic running time.

The recursive clause branching and prefix shortening distinguish this profile from [`random_3sat_greedy_dpll`](../random_3sat_greedy_dpll/README.md), whose package implements a no-backtrack DPLL trace. The `multi-literal-prefix-branch` workload case falsifies a two-literal prefix in one Procedure S branch and then solves its remaining tail in a child call.

## Provenance and rights

The source is the cited book chapter. This package is a clean-room implementation of its mathematical recurrence; it copies no chapter prose, figures, or source code and asserts no license over the chapter. The truth-table replacement subroutine and deterministic model/counter output are bounded benchmark refinements. See [`RIGHTS.md`](RIGHTS.md).

## Files

- [`workload.json`](workload.json)
- [primary recursive oracle](../../procedure_s_general_cnf_sat_oracle.py)
- [independent truth-mask verifier oracle](../../procedure_s_general_cnf_sat_verifier_oracle.py)

| Language | Port |
|---|---|
| C | [`c/p/procedure_s_general_cnf_sat.c`](../../../c/p/procedure_s_general_cnf_sat.c) |
| C3 | [`c3/p/procedure_s_general_cnf_sat.c3`](../../../c3/p/procedure_s_general_cnf_sat.c3) |
| C++ | [`cpp/p/procedure_s_general_cnf_sat.cpp`](../../../cpp/p/procedure_s_general_cnf_sat.cpp) |
| Elisa | [`elisa/p/procedure_s_general_cnf_sat.elisa`](../../../elisa/p/procedure_s_general_cnf_sat.elisa) |
| Nim | [`nim/p/procedure_s_general_cnf_sat.nim`](../../../nim/p/procedure_s_general_cnf_sat.nim) |
| Odin | [`odin/p/procedure_s_general_cnf_sat.odin`](../../../odin/p/procedure_s_general_cnf_sat.odin) |
| Rust | [`rust/p/procedure_s_general_cnf_sat.rs`](../../../rust/p/procedure_s_general_cnf_sat.rs) |
| V | [`v/p/procedure_s_general_cnf_sat.v`](../../../v/p/procedure_s_general_cnf_sat.v) |
| Zig | [`zig/p/procedure_s_general_cnf_sat.zig`](../../../zig/p/procedure_s_general_cnf_sat.zig) |
