# Two-SAT

This benchmark solves a conjunction of clauses, each containing two signed literals, with the implication graph and Kosaraju strongly connected components method.

## Contract

- Input is `[variable_count, clause_count, literal_a, literal_b, ...]`. Variables are numbered from 1; a negative literal means negation.
- There are 0–40 variables and 0–2,047 clauses. Each literal is nonzero and its absolute value is at most the variable count. The exact input length is `2 + 2 * clause_count`.
- A clause `(a ∨ b)` contributes `¬a → b` and `¬b → a`.
- Output is `[1, assignment_for_x1, ...]`, with each assignment byte 0 or 1, for a satisfiable formula. Unsatisfiable output is `[0]`. Invalid input returns `-1`; insufficient output capacity returns `-2`.
- Empty formulas are satisfiable, including the zero-variable formula.

The pinned Java `TwoSat` and Rust `solve_two_satisfiability` sources both construct this implication graph and use Kosaraju SCCs. Java exposes a satisfiable flag plus an assignment; Rust returns an assignment or the first conflicting variable. This package normalizes their common result to the encoding above.

[`workload.json`](workload.json) covers satisfiable and unsatisfiable formulas, repeated and unit-equivalent clauses, tautologies, empty input, malformed literals, and capacity limits. The independent solver is [`two_sat_oracle.py`](../../two_sat_oracle.py).
