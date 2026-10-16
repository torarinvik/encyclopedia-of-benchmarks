# Davis–Putnam–Logemann–Loveland

Decide whether a bounded conjunctive normal form (CNF) formula is satisfiable. The ports apply unit propagation and pure-literal elimination before branching over an unassigned variable.

## Contract

- Input is [variable_count, clause_count, clause_length, signed_literal...]. Variable ids are 1 through variable_count; a negative id denotes its negation.
- The input domain follows the pinned source's generated formulas: 0–5 variables, 0–10 clauses, and 0–5 literals per clause. Repeated literals collapse to one occurrence. A clause containing both a variable and its negation is a tautology.
- An empty formula is satisfiable; an empty clause is unsatisfiable. The result is 1 for satisfiable, 0 for unsatisfiable, and -1 for malformed input.
- This is a repaired implementation of the source's intended DPLL algorithm. The pinned Python branch uses `or` on nonempty (result, model) tuples, so a false result tuple is still truthy and the second branch is skipped. It also assigns both branch variables to the same mutable model. The benchmark returns only satisfiability, independent of which satisfying model is found. Branching always chooses the lowest-numbered unassigned variable and tries true before false, making the search deterministic.
- This general CNF solver is distinct from `two_sat`, which accepts only 2-CNF and solves it through an implication graph and strongly connected components.
- The ports use small integer masks and recursion bounded by five variables; they require no architecture-specific instructions.

## Pinned source

The source defines clause evaluation, pure-symbol detection, unit-clause propagation, and recursive DPLL branching in [TheAlgorithms/Python `davis_putnam_logemann_loveland.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/other/davis_putnam_logemann_loveland.py). Its random formula generator uses at most five variables, ten clauses, and five literals per clause. The oracle enumerates assignments independently to define the satisfiability result.

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm davis_putnam_logemann_loveland --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/d/davis_putnam_logemann_loveland/rust/build.json
```

## Language ports

| Language | Source |
| --- | --- |
| C | [c/d/davis_putnam_logemann_loveland.c](../../../c/d/davis_putnam_logemann_loveland.c) |
| C3 | [c3/d/davis_putnam_logemann_loveland.c3](../../../c3/d/davis_putnam_logemann_loveland.c3) |
| C++ | [cpp/d/davis_putnam_logemann_loveland.cpp](../../../cpp/d/davis_putnam_logemann_loveland.cpp) |
| Elisa | [elisa/d/davis_putnam_logemann_loveland.elisa](../../../elisa/d/davis_putnam_logemann_loveland.elisa) |
| Nim | [nim/d/davis_putnam_logemann_loveland.nim](../../../nim/d/davis_putnam_logemann_loveland.nim) |
| Odin | [odin/d/davis_putnam_logemann_loveland.odin](../../../odin/d/davis_putnam_logemann_loveland.odin) |
| Rust | [rust/d/davis_putnam_logemann_loveland.rs](../../../rust/d/davis_putnam_logemann_loveland.rs) |
| V | [v/d/davis_putnam_logemann_loveland.v](../../../v/d/davis_putnam_logemann_loveland.v) |
| Zig | [zig/d/davis_putnam_logemann_loveland.zig](../../../zig/d/davis_putnam_logemann_loveland.zig) |
