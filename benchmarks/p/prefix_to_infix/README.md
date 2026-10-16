# Prefix to infix

The pinned Java `PrefixToInfix.getPrefixToInfix` scans a prefix string from right to left. It pushes operands and, for each binary operator, pops the first operand and then the second before wrapping them as `(first operator second)`. Empty input returns an empty string; malformed stack shapes throw.

## Contract

Input is `[token_count, ASCII prefix bytes...]` with 0–63 tokens. Operands are ASCII letters and operators are `+`, `-`, `*`, `/`, and `^`. A valid expression has one final stack value. Output is the ASCII infix expression with every binary operation parenthesized; malformed inputs return `-1`. The maximum valid output is 125 bytes.

The benchmark excludes other non-operator ASCII characters even though the Java implementation pushes any non-operator character as an operand. This keeps the contract aligned with the documented letter/digit operand syntax and portable byte domain.

See [`workload.json`](workload.json) and the runtime [oracle](../../prefix_to_infix_oracle.py). Pinned source: [TheAlgorithms/Java `PrefixToInfix.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/stacks/PrefixToInfix.java).

| Language | Port |
|---|---|
| C | [`c/p/prefix_to_infix.c`](../../../c/p/prefix_to_infix.c) |
| C3 | [`c3/p/prefix_to_infix.c3`](../../../c3/p/prefix_to_infix.c3) |
| C++ | [`cpp/p/prefix_to_infix.cpp`](../../../cpp/p/prefix_to_infix.cpp) |
| Elisa | [`elisa/p/prefix_to_infix.elisa`](../../../elisa/p/prefix_to_infix.elisa) |
| Nim | [`nim/p/prefix_to_infix.nim`](../../../nim/p/prefix_to_infix.nim) |
| Odin | [`odin/p/prefix_to_infix.odin`](../../../odin/p/prefix_to_infix.odin) |
| Rust | [`rust/p/prefix_to_infix.rs`](../../../rust/p/prefix_to_infix.rs) |
| V | [`v/p/prefix_to_infix.v`](../../../v/p/prefix_to_infix.v) |
| Zig | [`zig/p/prefix_to_infix.zig`](../../../zig/p/prefix_to_infix.zig) |
