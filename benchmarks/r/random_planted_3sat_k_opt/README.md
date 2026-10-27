# Random planted 3-SAT k-OPT

This package implements the bounded deterministic k-OPT profile described in “Random Planted 3-SAT,” DOI [`10.1007/978-1-4939-2864-4_330`](https://doi.org/10.1007/978-1-4939-2864-4_330), drawing on Feige and Vilenchik's “A local search algorithm for 3-SAT” (Weizmann Institute technical report, 2004).

## Contract

- ABI: `i64_array_bytes_output`. Input is `[n,m,3m signed one-based literals]`, with `3 <= n <= 12`, `0 <= m <= 32`, and three distinct variables per clause.
- Start from the Majority Vote assignment: each variable takes its more frequent polarity; ties and unseen variables are false. Start with `k=1`.
- An improving move changes at least one and at most `k` variables and strictly enlarges the set of satisfied clause positions. Thus every currently satisfied clause remains satisfied and at least one previously unsatisfied clause becomes satisfied.
- Repeatedly select the lexicographically smallest satisfying assignment (false before true, variable order 1 through n) among all improving assignments at Hamming distance `1..k`. Continue at the same `k` until none exists; then increase `k` by one and continue from the current assignment.
- At a satisfying assignment, return status `1`. At a local optimum for `k=n`, return status `0` (unsatisfiable) and the final assignment. Output is `[status,assignment[0..n)]`, where assignment words are `1` for true and `-1` for false. Invalid input returns `-1`; null output or insufficient capacity returns `-2` without writing. Maximum output is 104 bytes.

The chapter leaves move arbitration unspecified; this profile fixes it by lexicographic order. The bounded implementation enumerates all assignments up to `n=12` to realize the paper's set-based improving-move semantics. Feige–Vilenchik describe a depth-k search tree that limits the search; this profile does not claim that running-time optimization or the paper's probabilistic performance guarantees. It is distinct from the local no-backtrack `random_3sat_greedy_dpll` and from PPSZ.

## Provenance and rights

Sources: “Random Planted 3-SAT,” *Encyclopedia of Algorithms*, DOI `10.1007/978-1-4939-2864-4_330`, and U. Feige and D. Vilenchik, “A local search algorithm for 3-SAT,” Weizmann Institute technical report (2004), [author-hosted PDF](https://www.wisdom.weizmann.ac.il/~feige/TechnicalReports/FeigeVilenchik.pdf). The book and report are used as behavioral references only; no source code or prose is copied. See [`RIGHTS.md`](RIGHTS.md).

## Files

- [`workload.json`](workload.json)
- [Primary set-mask oracle](../../random_planted_3sat_k_opt_oracle.py)
- [Independent clause-by-clause verifier oracle](../../random_planted_3sat_k_opt_verifier_oracle.py)

| Language | Port |
|---|---|
| C | [`c/r/random_planted_3sat_k_opt.c`](../../../c/r/random_planted_3sat_k_opt.c) |
| C3 | [`c3/r/random_planted_3sat_k_opt.c3`](../../../c3/r/random_planted_3sat_k_opt.c3) |
| C++ | [`cpp/r/random_planted_3sat_k_opt.cpp`](../../../cpp/r/random_planted_3sat_k_opt.cpp) |
| Elisa | [`elisa/r/random_planted_3sat_k_opt.elisa`](../../../elisa/r/random_planted_3sat_k_opt.elisa) |
| Nim | [`nim/r/random_planted_3sat_k_opt.nim`](../../../nim/r/random_planted_3sat_k_opt.nim) |
| Odin | [`odin/r/random_planted_3sat_k_opt.odin`](../../../odin/r/random_planted_3sat_k_opt.odin) |
| Rust | [`rust/r/random_planted_3sat_k_opt.rs`](../../../rust/r/random_planted_3sat_k_opt.rs) |
| V | [`v/r/random_planted_3sat_k_opt.v`](../../../v/r/random_planted_3sat_k_opt.v) |
| Zig | [`zig/r/random_planted_3sat_k_opt.zig`](../../../zig/r/random_planted_3sat_k_opt.zig) |
