# Evaluate expression

This benchmark follows the pinned JavaScript `evaluatePostfixExpression` algorithm. It evaluates tokens from left to right as Reverse Polish notation: operands are pushed, and each binary operator pops the right operand before the left. There is no infix precedence parsing.

## Contract

Input is `[token_count, opcode, payload, ...]`, with 1–64 tokens (at most 129 values). Opcode `0` pushes `payload / 1000.0`, where payload is an integer in `[-1,000,000,000, 1,000,000,000]`. Opcodes `1`, `2`, `3`, and `4` mean `+`, `-`, `*`, and `/`; operator payloads must be zero. Division uses binary64 floating-point and division by zero is invalid. A well-formed expression must leave exactly one stack value. The parser accepts up to 131 values so the 65-token boundary can be represented and rejected by the ABI with `-1`.

The function returns a little-endian output record: a `u32` status tag (`1` for a value, `0` for the source algorithm's `null`) followed by one little-endian IEEE-754 binary64 value when status is `1`. Malformed stack shape and division by zero produce tag `0`. Invalid packed inputs return `-1`; insufficient output capacity returns `-2`.

The numeric ABI uses thousandths so the workload can represent fractional values without locale-sensitive parsing. Evaluation preserves ordinary JavaScript numeric addition, subtraction, multiplication, and division semantics for this bounded input domain.

## Implementations

| Language | Source |
|---|---|
| C | [`c/e/evaluate_expression.c`](../../../c/e/evaluate_expression.c) |
| C3 | [`c3/e/evaluate_expression.c3`](../../../c3/e/evaluate_expression.c3) |
| C++ | [`cpp/e/evaluate_expression.cpp`](../../../cpp/e/evaluate_expression.cpp) |
| Elisa | [`elisa/e/evaluate_expression.elisa`](../../../elisa/e/evaluate_expression.elisa) |
| Nim | [`nim/e/evaluate_expression.nim`](../../../nim/e/evaluate_expression.nim) |
| Odin | [`odin/e/evaluate_expression.odin`](../../../odin/e/evaluate_expression.odin) |
| Rust | [`rust/e/evaluate_expression.rs`](../../../rust/e/evaluate_expression.rs) |
| V | [`v/e/evaluate_expression.v`](../../../v/e/evaluate_expression.v) |
| Zig | [`zig/e/evaluate_expression.zig`](../../../zig/e/evaluate_expression.zig) |

Pinned source: [TheAlgorithms/JavaScript `EvaluateExpression.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Stack/EvaluateExpression.js).
