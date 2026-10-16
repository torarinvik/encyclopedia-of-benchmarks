# Parentheses generator

The pinned Java source recursively generates every balanced-parenthesis string. At each position it tries an opening parenthesis first when fewer than n have been used, then a closing parenthesis when that would remain balanced.

## Contract

Input is `[n]` with `0 <= n <= 6`. Output bytes begin with the number of generated strings as a little-endian u16, followed by each fixed-width `2n`-byte ASCII string in source traversal order. The zero-pair case contains one empty string, represented by a count of one and no following string bytes. Negative and larger inputs return `-1`.

See [`workload.json`](workload.json) and the runtime [oracle](../../parentheses_generator_oracle.py). Pinned source: [TheAlgorithms/Java `ParenthesesGenerator.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/backtracking/ParenthesesGenerator.java).

| Language | Port |
|---|---|
| C | [`c/p/parentheses_generator.c`](../../../c/p/parentheses_generator.c) |
| C3 | [`c3/p/parentheses_generator.c3`](../../../c3/p/parentheses_generator.c3) |
| C++ | [`cpp/p/parentheses_generator.cpp`](../../../cpp/p/parentheses_generator.cpp) |
| Elisa | [`elisa/p/parentheses_generator.elisa`](../../../elisa/p/parentheses_generator.elisa) |
| Nim | [`nim/p/parentheses_generator.nim`](../../../nim/p/parentheses_generator.nim) |
| Odin | [`odin/p/parentheses_generator.odin`](../../../odin/p/parentheses_generator.odin) |
| Rust | [`rust/p/parentheses_generator.rs`](../../../rust/p/parentheses_generator.rs) |
| V | [`v/p/parentheses_generator.v`](../../../v/p/parentheses_generator.v) |
| Zig | [`zig/p/parentheses_generator.zig`](../../../zig/p/parentheses_generator.zig) |
