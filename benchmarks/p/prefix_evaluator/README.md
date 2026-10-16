# Prefix evaluator

The pinned Java evaluator reads a whitespace-delimited prefix expression from right to left using a stack. It supports integer operands and binary `+`, `-`, `*`, and `/`; operators pop operand one before operand two, so subtraction and division preserve prefix order. Java `int` arithmetic wraps for addition, subtraction, and multiplication, and integer division truncates toward zero.

## Contract

The ABI input is `[token_count, token...]`, with 1 through 128 tokens. Integer operands must fit signed 32-bit. Operators are encoded as `-9000000000000000001` (`+`), `-9000000000000000002` (`-`), `-9000000000000000003` (`*`), and `-9000000000000000004` (`/`). The token array must form a valid prefix expression and leave exactly one value. Malformed expressions, stack underflow, division by zero, and non-i32 operands return `-1`.

See [`workload.json`](workload.json) and the runtime [oracle](../../prefix_evaluator_oracle.py). Pinned source: [TheAlgorithms/Java `PrefixEvaluator.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/stacks/PrefixEvaluator.java).

| Language | Port |
|---|---|
| C | [`c/p/prefix_evaluator.c`](../../../c/p/prefix_evaluator.c) |
| C3 | [`c3/p/prefix_evaluator.c3`](../../../c3/p/prefix_evaluator.c3) |
| C++ | [`cpp/p/prefix_evaluator.cpp`](../../../cpp/p/prefix_evaluator.cpp) |
| Elisa | [`elisa/p/prefix_evaluator.elisa`](../../../elisa/p/prefix_evaluator.elisa) |
| Nim | [`nim/p/prefix_evaluator.nim`](../../../nim/p/prefix_evaluator.nim) |
| Odin | [`odin/p/prefix_evaluator.odin`](../../../odin/p/prefix_evaluator.odin) |
| Rust | [`rust/p/prefix_evaluator.rs`](../../../rust/p/prefix_evaluator.rs) |
| V | [`v/p/prefix_evaluator.v`](../../../v/p/prefix_evaluator.v) |
| Zig | [`zig/p/prefix_evaluator.zig`](../../../zig/p/prefix_evaluator.zig) |
