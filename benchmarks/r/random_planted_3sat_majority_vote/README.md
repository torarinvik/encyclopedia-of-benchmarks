# Random planted 3-SAT majority vote

This package captures the chapter's initial Majority Vote heuristic from “Random Planted 3-SAT,” DOI [`10.1007/978-1-4939-2864-4_330`](https://doi.org/10.1007/978-1-4939-2864-4_330). It counts the positive and negative occurrences of every variable and chooses its more frequent polarity.

## Contract

- ABI: `i64_array_bytes_output`. Input is `[n,m,3m signed one-based literals]` in clause order. Each clause has three distinct variables; `3 <= n <= 12`, `0 <= m <= 32`.
- For variable `v`, set it true exactly when its positive occurrence count exceeds its negative count. Ties, including unseen variables, are false.
- Output is one signed-i64 word per variable (`1` for true, `-1` for false), little-endian. Invalid input returns `-1`; null output or insufficient capacity returns `-2` without writing. Maximum output is 96 bytes.

This package measures only the deterministic initialization step. It does not generate planted formulas or claim a success-probability theorem. It differs from `random_3sat_greedy_dpll`, which chooses a changing most-frequent literal during a no-backtrack residual-formula trace.

## Provenance and rights

Source: “Random Planted 3-SAT,” *Encyclopedia of Algorithms*, DOI `10.1007/978-1-4939-2864-4_330`, which describes majority polarity assignment. The package is clean-room based on the chapter description; no book prose or code is copied. The chapter grants no source-code license. See [`RIGHTS.md`](RIGHTS.md).

## Files

- [`workload.json`](workload.json)
- [Primary occurrence-count oracle](../../random_planted_3sat_majority_vote_oracle.py)
- [Independent per-variable verifier oracle](../../random_planted_3sat_majority_vote_verifier_oracle.py)

| Language | Port |
|---|---|
| C | [`c/r/random_planted_3sat_majority_vote.c`](../../../c/r/random_planted_3sat_majority_vote.c) |
| C3 | [`c3/r/random_planted_3sat_majority_vote.c3`](../../../c3/r/random_planted_3sat_majority_vote.c3) |
| C++ | [`cpp/r/random_planted_3sat_majority_vote.cpp`](../../../cpp/r/random_planted_3sat_majority_vote.cpp) |
| Elisa | [`elisa/r/random_planted_3sat_majority_vote.elisa`](../../../elisa/r/random_planted_3sat_majority_vote.elisa) |
| Nim | [`nim/r/random_planted_3sat_majority_vote.nim`](../../../nim/r/random_planted_3sat_majority_vote.nim) |
| Odin | [`odin/r/random_planted_3sat_majority_vote.odin`](../../../odin/r/random_planted_3sat_majority_vote.odin) |
| Rust | [`rust/r/random_planted_3sat_majority_vote.rs`](../../../rust/r/random_planted_3sat_majority_vote.rs) |
| V | [`v/r/random_planted_3sat_majority_vote.v`](../../../v/r/random_planted_3sat_majority_vote.v) |
| Zig | [`zig/r/random_planted_3sat_majority_vote.zig`](../../../zig/r/random_planted_3sat_majority_vote.zig) |
