# Infix to Postfix

This benchmark converts a bounded ASCII infix expression to postfix form using the Rust source's shunting-yard rules. Operands are single ASCII letters or digits. Supported operators are `+`, `-`, `*`, `/`, and `^`; precedence is 1, 2, and 3 respectively. Equal precedence is left-associative, including `^`. Parentheses group expressions. The source silently ignores an unmatched closing parenthesis after flushing pending operators; the ports preserve this behavior.

The workload includes expressions up to 24 bytes and at most 10 pending operators or opening parentheses, matching the fixed-size benchmark ABI. Inputs use no whitespace or unary operators; one case preserves the source's unmatched-closing-parenthesis behavior. The output is the postfix byte sequence followed by a NUL byte. The ports return `-1` for malformed or unsupported input and `-2` when the output buffer is too small.

| Language | Source |
|---|---|
| Rust | [`rust/i/infix_to_postfix.rs`](../../../rust/i/infix_to_postfix.rs) |
| C | [`c/i/infix_to_postfix.c`](../../../c/i/infix_to_postfix.c) |
| C3 | [`c3/i/infix_to_postfix.c3`](../../../c3/i/infix_to_postfix.c3) |
| C++ | [`cpp/i/infix_to_postfix.cpp`](../../../cpp/i/infix_to_postfix.cpp) |
| Elisa | [`elisa/i/infix_to_postfix.elisa`](../../../elisa/i/infix_to_postfix.elisa) |
| Nim | [`nim/i/infix_to_postfix.nim`](../../../nim/i/infix_to_postfix.nim) |
| Odin | [`odin/i/infix_to_postfix.odin`](../../../odin/i/infix_to_postfix.odin) |
| V | [`v/i/infix_to_postfix.v`](../../../v/i/infix_to_postfix.v) |
| Zig | [`zig/i/infix_to_postfix.zig`](../../../zig/i/infix_to_postfix.zig) |

## Source

- [TheAlgorithms/Rust `infix_to_postfix.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/infix_to_postfix.rs)

