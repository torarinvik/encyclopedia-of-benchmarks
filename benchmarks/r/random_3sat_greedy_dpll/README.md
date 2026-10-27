# Random 3-SAT Greedy DPLL

This package implements the chapter's no-backtrack DPLL `Greedy` profile from “Thresholds of Random k-SAT,” DOI [`10.1007/978-1-4939-2864-4_423`](https://doi.org/10.1007/978-1-4939-2864-4_423). It is distinct from the repository's `davis_putnam_logemann_loveland`: this profile forces unit clauses, then branches on the literal with the greatest current occurrence count, and never backtracks.

## Bounded contract

- ABI: `i64_array_bytes_output`. Input is `[n, m, literal_0, ..., literal_(3m-1)]`, with clauses in source order and each clause containing exactly three signed, one-based variable IDs. Positive `v` denotes variable `v`; negative `-v` denotes its negation.
- Bounds: `3 <= n <= 12`, `0 <= m <= 32`, and input length is exactly `2 + 3m` words (at most 98). Literals must be nonzero, in range, and use three distinct variables per clause.
- At each step, choose the first current unit clause in original formula order, if one exists. Otherwise choose the literal with the largest occurrence count in the current residual formula; ties use the lower variable ID, with positive before negative. Set that literal true, delete satisfied clauses, and remove its negation from every other clause. If a clause becomes empty, stop and report failure. There is no backtracking.
- If no clauses remain, report success and fill any unassigned variables with false. On failure, return the partial assignment reached at the first empty clause; unassigned entries are zero.
- Output is `[success_bit, assignment[0..n)]`, encoded as little-endian signed-i64 words. Assignment values are `1` for true, `-1` for false, and `0` for unassigned. The maximum output is 104 bytes.

The profile captures the source's Greedy trace only. It does not benchmark random formula generation or claim the chapter's random-threshold, success-probability, or asymptotic results. The local DPLL benchmark has backtracking and additional propagation rules, so it is related but not an algorithm duplicate.

## Provenance and rights

Source: “Thresholds of Random k-SAT,” *Encyclopedia of Algorithms*, DOI `10.1007/978-1-4939-2864-4_423`, especially the Key Results description of backtrack-free DPLL and Algorithm Greedy. The chapter is copyrighted and does not grant a source-code license. This package is independently written from the described behavior; it contains no copied book prose or source code. See [`RIGHTS.md`](RIGHTS.md).

## Files

- [`workload.json`](workload.json)
- [Primary mutable-clause oracle](../../random_3sat_greedy_dpll_oracle.py)
- [Independent bit-mask verifier oracle](../../random_3sat_greedy_dpll_verifier_oracle.py)

| Language | Port |
|---|---|
| C | [`c/r/random_3sat_greedy_dpll.c`](../../../c/r/random_3sat_greedy_dpll.c) |
| C3 | [`c3/r/random_3sat_greedy_dpll.c3`](../../../c3/r/random_3sat_greedy_dpll.c3) |
| C++ | [`cpp/r/random_3sat_greedy_dpll.cpp`](../../../cpp/r/random_3sat_greedy_dpll.cpp) |
| Elisa | [`elisa/r/random_3sat_greedy_dpll.elisa`](../../../elisa/r/random_3sat_greedy_dpll.elisa) |
| Nim | [`nim/r/random_3sat_greedy_dpll.nim`](../../../nim/r/random_3sat_greedy_dpll.nim) |
| Odin | [`odin/r/random_3sat_greedy_dpll.odin`](../../../odin/r/random_3sat_greedy_dpll.odin) |
| Rust | [`rust/r/random_3sat_greedy_dpll.rs`](../../../rust/r/random_3sat_greedy_dpll.rs) |
| V | [`v/r/random_3sat_greedy_dpll.v`](../../../v/r/random_3sat_greedy_dpll.v) |
| Zig | [`zig/r/random_3sat_greedy_dpll.zig`](../../../zig/r/random_3sat_greedy_dpll.zig) |
