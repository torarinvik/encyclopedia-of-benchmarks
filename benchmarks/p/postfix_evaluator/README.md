# Postfix evaluator

This benchmark follows the pinned Java stack evaluator. Tokens are whitespace-delimited signed integers or one of `+`, `-`, `*`, `/`; operators pop the right operand first and then the left operand. Java `int` addition, subtraction, and multiplication wrap to signed 32-bit values, and division truncates toward zero (including `INT_MIN / -1` wrapping to `INT_MIN`).

## Contract

The ABI input is `[token_count, token...]`, with 1 through 128 tokens. Integer operands must fit signed 32-bit. Operators are encoded as `-9000000000000000001` (`+`), `-9000000000000000002` (`-`), `-9000000000000000003` (`*`), and `-9000000000000000004` (`/`). The array length must equal `token_count + 1`; evaluation must leave exactly one value on the stack. Invalid syntax, non-i32 operands, stack underflow, leftover values, and division by zero return `-1`.

See [`workload.json`](workload.json) and the runtime [oracle](../../postfix_evaluator_oracle.py). Pinned source: [TheAlgorithms/Java `PostfixEvaluator.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/stacks/PostfixEvaluator.java).

| Language | Port |
|---|---|
| C | [`c/p/postfix_evaluator.c`](../../../c/p/postfix_evaluator.c) |
| C3 | [`c3/p/postfix_evaluator.c3`](../../../c3/p/postfix_evaluator.c3) |
| C++ | [`cpp/p/postfix_evaluator.cpp`](../../../cpp/p/postfix_evaluator.cpp) |
| Elisa | [`elisa/p/postfix_evaluator.elisa`](../../../elisa/p/postfix_evaluator.elisa) |
| Nim | [`nim/p/postfix_evaluator.nim`](../../../nim/p/postfix_evaluator.nim) |
| Odin | [`odin/p/postfix_evaluator.odin`](../../../odin/p/postfix_evaluator.odin) |
| Rust | [`rust/p/postfix_evaluator.rs`](../../../rust/p/postfix_evaluator.rs) |
| V | [`v/p/postfix_evaluator.v`](../../../v/p/postfix_evaluator.v) |
| Zig | [`zig/p/postfix_evaluator.zig`](../../../zig/p/postfix_evaluator.zig) |
