# Postfix evaluation

Postfix (Reverse Polish) evaluation scans tokens from left to right, pushing operands and applying each operator to the top two stack values. The upstream candidates vary in numeric types and supported operators; this benchmark standardizes the common binary operations.

## Contract

Input is a sequence of `[opcode, payload]` pairs:

- `0, value` pushes an operand in `[-1,000,000, 1,000,000]`.
- `1, 0` adds the top two operands.
- `2, 0` subtracts the top operand from the one below it.
- `3, 0` multiplies the top two operands.
- `4, 0` divides the value below the top by the top, truncating toward zero.

Inputs contain between 1 and 256 tokens. A valid expression leaves exactly one stack value. Intermediate and final results must stay within `[-1,000,000,000, 1,000,000,000]`. Malformed input, division by zero, and out-of-range arithmetic return `-1,000,000,001`, a value outside the valid result range.

All ports use a fixed-capacity stack and O(n) time with O(n) extra space.

## Reproduce

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm postfix_evaluation --language c
python3 benchmarks/run_i64_array_scalar.py --algorithm postfix_evaluation
python3 benchmarks/verify_postfix_evaluation.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1
```

The verifier exhausts short token sequences, generates deterministic valid expressions and malformed arrays, and checks division, range, and stack-depth boundaries against an independent arbitrary-precision oracle.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/postfix_evaluation.c`](../../../c/p/postfix_evaluation.c) |
| C3 | [`c3/p/postfix_evaluation.c3`](../../../c3/p/postfix_evaluation.c3) |
| C++ | [`cpp/p/postfix_evaluation.cpp`](../../../cpp/p/postfix_evaluation.cpp) |
| Elisa | [`elisa/p/postfix_evaluation.elisa`](../../../elisa/p/postfix_evaluation.elisa) |
| Nim | [`nim/p/postfix_evaluation.nim`](../../../nim/p/postfix_evaluation.nim) |
| Odin | [`odin/p/postfix_evaluation.odin`](../../../odin/p/postfix_evaluation.odin) |
| Rust | [`rust/p/postfix_evaluation.rs`](../../../rust/p/postfix_evaluation.rs) |
| V | [`v/p/postfix_evaluation.v`](../../../v/p/postfix_evaluation.v) |
| Zig | [`zig/p/postfix_evaluation.zig`](../../../zig/p/postfix_evaluation.zig) |

## TheAlgorithms references

- [C `postfix_evaluation.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/misc/postfix_evaluation.c)
- [C++ `postfix_evaluation.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/others/postfix_evaluation.cpp) and [additional C++ copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/others/postfix_evaluation.cpp)
- [Python `postfix_evaluation.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/stacks/postfix_evaluation.py)
- [Rust `postfix_evaluation.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/postfix_evaluation.rs)
