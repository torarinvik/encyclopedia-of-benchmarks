# Addition rule of probability

## Contract

The pinned C++ candidate provides formulas for the probability of `A or B` for independent and dependent events. This benchmark combines both functions into one three-input interface: the inputs are `P(A)`, `P(B)`, and `P(B | A)`, and the returned binary64 value is

`P(A or B) = P(A) + P(B) - P(A) * P(B | A)`.

For independent events, set `P(B | A) = P(B)`, which gives the candidate's independent formula. Inputs are finite probabilities in `[0, 1]`. The source formula does not validate whether the three values are jointly consistent as event probabilities; the benchmark preserves that arithmetic behavior. No rounding is applied beyond the target language's ordinary binary64 operations.

## Workload and verification

[`workload.json`](workload.json) covers the independent and dependent formulas, boundary probabilities, and fractional inputs. Build and run with the `float64_triple` ABI family:

```sh
python3 benchmarks/build_abi.py --family float64_triple --algorithm addition_rule --language rust --with-checker
python3 benchmarks/run_float64_triple.py --build-manifest build/float64_triple/a/addition_rule/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/addition_rule.c`](../../../c/a/addition_rule.c) |
| C3 | [`c3/a/addition_rule.c3`](../../../c3/a/addition_rule.c3) |
| C++ | [`cpp/a/addition_rule.cpp`](../../../cpp/a/addition_rule.cpp) |
| Elisa | [`elisa/a/addition_rule.elisa`](../../../elisa/a/addition_rule.elisa) |
| Nim | [`nim/a/addition_rule.nim`](../../../nim/a/addition_rule.nim) |
| Odin | [`odin/a/addition_rule.odin`](../../../odin/a/addition_rule.odin) |
| Rust | [`rust/a/addition_rule.rs`](../../../rust/a/addition_rule.rs) |
| V | [`v/a/addition_rule.v`](../../../v/a/addition_rule.v) |
| Zig | [`zig/a/addition_rule.zig`](../../../zig/a/addition_rule.zig) |

## Reviewed source variants

- [C++ `addition_rule.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/probability/addition_rule.cpp)
- [C++-1 `addition_rule.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/probability/addition_rule.cpp)
