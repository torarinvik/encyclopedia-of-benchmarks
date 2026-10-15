# Conditional probability

## Contract

Given the joint probability `P(A ∩ B)` and the conditioning probability `P(B)`, return `P(A | B)`:

`P(A | B) = P(A ∩ B) / P(B)`.

The two finite binary64 inputs are ordered as `[P(A ∩ B), P(B)]`. `P(B)` must lie in `(0, 1]`, and `P(A ∩ B)` must lie in `[0, P(B)]`. Invalid inputs return `-1.0`. The exported ABI is `double conditional_probability(double probability_intersection, double probability_b)`.

## Relation to Bayes Theorem and Addition Rule

This contract receives a joint event probability directly and performs the conditional-probability ratio. [`bayes_theorem`](../../b/bayes_theorem/README.md) instead receives `P(A)`, `P(B)`, and `P(B | A)` and reconstructs the joint probability as `P(A) * P(B | A)` before dividing by `P(B)`. They can produce the same posterior when the inputs describe the same events, but have different input data and computation contracts. [`addition_rule`](../../a/addition_rule/README.md) shares the three-input probability representation with Bayes Theorem and computes `P(A ∪ B)`, so its output is different as well.

The pinned C++ source throws `std::invalid_argument` for out-of-domain probabilities. This benchmark maps those invalid cases to the shared `-1.0` sentinel and additionally requires finite inputs.

## Workload and recording

[`workload.json`](workload.json) covers the source examples, boundary probabilities, tiny probabilities, and invalid probability relationships. Runtime verification remains pending. Build and record with the shared `float64_pair` ABI:

```sh
python3 benchmarks/build_abi.py --family float64_pair --algorithm conditional_probability --language rust
python3 benchmarks/run_float64_pair.py --build-manifest build/float64_pair/c/conditional_probability/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/conditional_probability.c`](../../../c/c/conditional_probability.c) |
| C3 | [`c3/c/conditional_probability.c3`](../../../c3/c/conditional_probability.c3) |
| C++ | [`cpp/c/conditional_probability.cpp`](../../../cpp/c/conditional_probability.cpp) |
| Elisa | [`elisa/c/conditional_probability.elisa`](../../../elisa/c/conditional_probability.elisa) |
| Nim | [`nim/c/conditional_probability.nim`](../../../nim/c/conditional_probability.nim) |
| Odin | [`odin/c/conditional_probability.odin`](../../../odin/c/conditional_probability.odin) |
| Rust | [`rust/c/conditional_probability.rs`](../../../rust/c/conditional_probability.rs) |
| V | [`v/c/conditional_probability.v`](../../../v/c/conditional_probability.v) |
| Zig | [`zig/c/conditional_probability.zig`](../../../zig/c/conditional_probability.zig) |

## TheAlgorithms reference

- C++ [`conditional_probability.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/probability/conditional_probability.cpp)
