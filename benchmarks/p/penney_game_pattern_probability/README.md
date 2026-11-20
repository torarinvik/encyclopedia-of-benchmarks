# Penney game pattern-first probability

This benchmark returns the exact probability that binary pattern **A** appears before binary pattern **B** in an unbounded stream of independent fair coin tosses. The `i64_array_scalar` input is exactly `[L, A_mask, B_mask]`. `L` is in `1..=4`; each nonnegative mask is less than `2^L` and denotes an `L`-bit word read most-significant bit first. The two masks must differ. Valid output is the probability modulo `998244353`; null, malformed, or invalid input returns `-1`.

For example, `[2, 0, 2]` represents A=`00` and B=`10`; its result is `249561089`, the residue of `1/4`. Reversing the patterns gives `[2, 2, 0]` and result `748683265`, the residue of `3/4`. The length-one pair `[1, 0, 1]` has equal odds and returns `499122177`.

## Method and bounds

The primary method builds a deterministic suffix automaton whose states are the empty word and the distinct proper prefixes of A and B. Appending each possible bit either completes A, completes B, or moves to the longest suffix that is one of those prefix states. If `p[s]` is the probability of an eventual A win from transient state `s`, then

`2 p[s] - Σ p[next] = number of A-winning bit transitions from s`.

The resulting linear system is solved over the field modulo `998244353`; the empty-state solution is returned. Since the patterns are distinct and have equal length, a transition cannot complete both patterns. Each stream eventually hits one of the two patterns with probability one.

With `S` automaton states, `S <= 1 + 2(L - 1) <= 7`. The bounded prefix and transition construction costs `O(S²L)` operations, modular Gaussian elimination costs `O(S³)`, and modular inverses cost `O(S log 998244353)`. The primary scratch matrix and state arrays use `O(S²)` space. All modular products fit signed 64-bit arithmetic because `(998244352)² < 2^63 - 1`.

The independent reference uses every binary suffix word of length less than `L` as a state (`T = 2^L - 1 <= 15`) and solves the absorption equations with exact rational arithmetic before reducing the result modulo `998244353`. It uses a different state space and arithmetic from the primary reference. Its dense solve takes `O(T³)` rational operations and `O(T²)` matrix space.

## Sources and distinction

Brofos, [“A Markov Chain Analysis of a Pattern Matching Coin Game”](https://arxiv.org/abs/1406.2212), provides method context for first-arrival probabilities of overlapping patterns. The [pinned RosettaCodeData popular-task index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks) supplied the public title `Penneys-game` and its score of 49 only. No Rosetta task prose, code, examples, or tests were used.

This benchmark evaluates exact eventual first-arrival probability for a pair of patterns. It is distinct from simulating a finite number of tosses and from searching a supplied finite string.

## Package files

The prefix-state reference is [`primary_oracle.py`](primary_oracle.py); the all-suffix exact-rational reference is [`independent_oracle.py`](independent_oracle.py). Bounded and invalid-frame fixtures are in [`workload.json`](workload.json). [`verify_workload.py`](verify_workload.py) checks the metadata, fixture frames, references, documentation provenance, and the ten source ports; it is provided for later validation and has not been run. See [`RIGHTS.md`](RIGHTS.md) for provenance and [`INVENTORY.md`](INVENTORY.md) for the package contents.

## Language ports

| Language | Source |
|---|---|
| C | [`c/p/penney_game_pattern_probability.c`](../../../c/p/penney_game_pattern_probability.c) |
| C3 | [`c3/p/penney_game_pattern_probability.c3`](../../../c3/p/penney_game_pattern_probability.c3) |
| C++ | [`cpp/p/penney_game_pattern_probability.cpp`](../../../cpp/p/penney_game_pattern_probability.cpp) |
| Elisa | [`elisa/p/penney_game_pattern_probability.elisa`](../../../elisa/p/penney_game_pattern_probability.elisa) |
| Mojo | [`mojo/p/penney_game_pattern_probability.mojo`](../../../mojo/p/penney_game_pattern_probability.mojo) |
| Nim | [`nim/p/penney_game_pattern_probability.nim`](../../../nim/p/penney_game_pattern_probability.nim) |
| Odin | [`odin/p/penney_game_pattern_probability.odin`](../../../odin/p/penney_game_pattern_probability.odin) |
| Rust | [`rust/p/penney_game_pattern_probability.rs`](../../../rust/p/penney_game_pattern_probability.rs) |
| V | [`v/p/penney_game_pattern_probability.v`](../../../v/p/penney_game_pattern_probability.v) |
| Zig | [`zig/p/penney_game_pattern_probability.zig`](../../../zig/p/penney_game_pattern_probability.zig) |

All package artifacts received source-only review. No benchmark or validation programs, tests, builds, compilers, or benchmarks were run.
