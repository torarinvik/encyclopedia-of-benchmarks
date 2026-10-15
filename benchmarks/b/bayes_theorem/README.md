# Bayes' theorem

## Contract

Given `P(A)`, `P(B)`, and `P(B | A)`, return the posterior `P(A | B)`:

`P(A | B) = P(B | A) * P(A) / P(B)`.

The three finite binary64 inputs are ordered as `[P(A), P(B), P(B | A)]`. Each must lie in `[0, 1]`, `P(B)` must be positive, and the inputs must be coherent (`P(A) * P(B | A) <= P(B)`). Invalid inputs return `-1.0`. The coherence condition ensures the result is a probability in `[0, 1]`. The exported ABI is `double bayes_theorem(double probability_a, double probability_b, double probability_b_given_a)`.

## Source review and relation to Addition Rule

The pinned C++ sources expose `bayes_AgivenB(BgivenA, A, B) = BgivenA * A / B` and its algebraic reverse `bayes_BgivenA(AgivenB, A, B) = AgivenB * B / A`. This benchmark selects the main `P(A | B)` direction. It uses the same probability inputs as [`addition_rule`](../../a/addition_rule/README.md), but returns a conditional probability instead of `P(A or B)`, so it is a distinct operation. Unlike Addition Rule's arithmetic-only contract, Bayes inputs must be coherent and have nonzero evidence probability.

## Workload and recording

[`workload.json`](workload.json) covers the pinned source example, independent and dependent events, boundary probabilities, impossible event triples, and zero evidence. Runtime verification remains pending. Build and record with the shared `float64_triple` ABI:

```sh
python3 benchmarks/build_abi.py --family float64_triple --algorithm bayes_theorem --language rust
python3 benchmarks/run_float64_triple.py --build-manifest build/float64_triple/b/bayes_theorem/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/bayes_theorem.c`](../../../c/b/bayes_theorem.c) |
| C3 | [`c3/b/bayes_theorem.c3`](../../../c3/b/bayes_theorem.c3) |
| C++ | [`cpp/b/bayes_theorem.cpp`](../../../cpp/b/bayes_theorem.cpp) |
| Elisa | [`elisa/b/bayes_theorem.elisa`](../../../elisa/b/bayes_theorem.elisa) |
| Nim | [`nim/b/bayes_theorem.nim`](../../../nim/b/bayes_theorem.nim) |
| Odin | [`odin/b/bayes_theorem.odin`](../../../odin/b/bayes_theorem.odin) |
| Rust | [`rust/b/bayes_theorem.rs`](../../../rust/b/bayes_theorem.rs) |
| V | [`v/b/bayes_theorem.v`](../../../v/b/bayes_theorem.v) |
| Zig | [`zig/b/bayes_theorem.zig`](../../../zig/b/bayes_theorem.zig) |

## TheAlgorithms references

- C++ [`bayes_theorem.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/probability/bayes_theorem.cpp)
- C++-1 [`bayes_theorem.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/probability/bayes_theorem.cpp)
