# Parenthesis matching

The pinned C++ program reads one whitespace-delimited token and scans it with a stack. It recognizes opening and closing pairs `()`, `{}`, `[]`, and `<>`; every other character is a mismatch. A token is accepted only when each closer matches the top opener and the stack is empty at the end.

## Contract

Input is `[length, ASCII character codes...]`, with 1 through 99 visible ASCII characters (codes 33 through 126). Spaces cannot appear because the source reads a token. Output is 1 for a valid balanced expression, 0 for a nonmatching expression, and -1 for malformed/out-of-range ABI input. Each benchmark call starts with an empty stack, matching a fresh execution of the source program; length 99 keeps the stack within the source’s 100-character storage.

See [`workload.json`](workload.json) and the runtime [oracle](../../paranthesis_matching_oracle.py). Pinned source: [TheAlgorithms/C-Plus-Plus `paranthesis_matching.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/others/paranthesis_matching.cpp).

| Language | Port |
|---|---|
| C | [`c/p/paranthesis_matching.c`](../../../c/p/paranthesis_matching.c) |
| C3 | [`c3/p/paranthesis_matching.c3`](../../../c3/p/paranthesis_matching.c3) |
| C++ | [`cpp/p/paranthesis_matching.cpp`](../../../cpp/p/paranthesis_matching.cpp) |
| Elisa | [`elisa/p/paranthesis_matching.elisa`](../../../elisa/p/paranthesis_matching.elisa) |
| Nim | [`nim/p/paranthesis_matching.nim`](../../../nim/p/paranthesis_matching.nim) |
| Odin | [`odin/p/paranthesis_matching.odin`](../../../odin/p/paranthesis_matching.odin) |
| Rust | [`rust/p/paranthesis_matching.rs`](../../../rust/p/paranthesis_matching.rs) |
| V | [`v/p/paranthesis_matching.v`](../../../v/p/paranthesis_matching.v) |
| Zig | [`zig/p/paranthesis_matching.zig`](../../../zig/p/paranthesis_matching.zig) |
