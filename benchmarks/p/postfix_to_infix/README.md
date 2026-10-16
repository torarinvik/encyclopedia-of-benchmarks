# Postfix to infix

The pinned Java `getPostfixToInfix` converts postfix expressions with a stack of strings. For each binary operator it pops the right operand and then the left operand, builds `(left operator right)`, and pushes the result. Empty input returns an empty string, and a single alphabetic character is accepted unchanged.

## Contract

Input is `[token_count, ASCII postfix bytes...]`, with 0 to 64 tokens. Operands are ASCII letters and operators are `+`, `-`, `*`, `/`, and `^`. Output is the ASCII infix expression with each binary operation parenthesized. Invalid expressions return `-1`; insufficient workspace capacity returns `-2`. The ABI provides an 8,192-byte scratch/output buffer, and the maximum valid result is 125 bytes.

See [`workload.json`](workload.json) and the runtime [oracle](../../postfix_to_infix_oracle.py). Pinned source: [TheAlgorithms/Java `PostfixToInfix.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/stacks/PostfixToInfix.java).

| Language | Port |
|---|---|
| C | [`c/p/postfix_to_infix.c`](../../../c/p/postfix_to_infix.c) |
| C3 | [`c3/p/postfix_to_infix.c3`](../../../c3/p/postfix_to_infix.c3) |
| C++ | [`cpp/p/postfix_to_infix.cpp`](../../../cpp/p/postfix_to_infix.cpp) |
| Elisa | [`elisa/p/postfix_to_infix.elisa`](../../../elisa/p/postfix_to_infix.elisa) |
| Nim | [`nim/p/postfix_to_infix.nim`](../../../nim/p/postfix_to_infix.nim) |
| Odin | [`odin/p/postfix_to_infix.odin`](../../../odin/p/postfix_to_infix.odin) |
| Rust | [`rust/p/postfix_to_infix.rs`](../../../rust/p/postfix_to_infix.rs) |
| V | [`v/p/postfix_to_infix.v`](../../../v/p/postfix_to_infix.v) |
| Zig | [`zig/p/postfix_to_infix.zig`](../../../zig/p/postfix_to_infix.zig) |
