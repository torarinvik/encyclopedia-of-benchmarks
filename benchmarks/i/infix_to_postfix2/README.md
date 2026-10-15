# Infix to Postfix Conversion (C Stack Variant)

This package ports the pinned C `convert` routine, which scans one-character operands and uses a character stack to produce postfix notation.

## Contract

- Input is a byte array containing 1 to 24 ASCII characters, with no whitespace. Operands are ASCII letters or digits; operators are `+`, `-`, `*`, `/`, `%`; parentheses must be balanced.
- Operator precedence matches the source: `*`, `/`, and `%` have precedence 1; `+` and `-` have precedence 0. Equal-precedence operators are left-associative.
- The stack is limited to 10 entries. Postfix output is ASCII followed by one NUL byte; the return value includes the terminator.
- Invalid expressions return `-1`; insufficient output capacity returns `-2`.

[`workload.json`](workload.json) includes both pinned C examples, precedence and associativity cases, `%`, and malformed expressions. The runner computes expected postfix output with a separate shunting-yard oracle.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/i/infix_to_postfix2.c`](../../../c/i/infix_to_postfix2.c) |
| C3 | [`c3/i/infix_to_postfix2.c3`](../../../c3/i/infix_to_postfix2.c3) |
| C++ | [`cpp/i/infix_to_postfix2.cpp`](../../../cpp/i/infix_to_postfix2.cpp) |
| Elisa | [`elisa/i/infix_to_postfix2.elisa`](../../../elisa/i/infix_to_postfix2.elisa) |
| Nim | [`nim/i/infix_to_postfix2.nim`](../../../nim/i/infix_to_postfix2.nim) |
| Odin | [`odin/i/infix_to_postfix2.odin`](../../../odin/i/infix_to_postfix2.odin) |
| Rust | [`rust/i/infix_to_postfix2.rs`](../../../rust/i/infix_to_postfix2.rs) |
| V | [`v/i/infix_to_postfix2.v`](../../../v/i/infix_to_postfix2.v) |
| Zig | [`zig/i/infix_to_postfix2.zig`](../../../zig/i/infix_to_postfix2.zig) |

## Pinned source

- [TheAlgorithms/C `infix_to_postfix2.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/conversions/infix_to_postfix2.c)
