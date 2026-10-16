# Parenthesis counter

The pinned Go `Parenthesis` function increments a counter for `(`, decrements it for `)`, fails as soon as the count becomes negative, and returns whether the final count is zero. All other runes are ignored.

## Contract

Input is `[byte_count, ASCII bytes...]`, with at most 128 bytes. The scalar result is 1 for balanced parentheses and 0 otherwise. Non-parenthesis ASCII bytes are ignored, matching Go's switch. The pinned C file is a different stack program that also recognizes square and curly brackets and treats non-opening characters as closers; it is documented as divergent.

See [`workload.json`](workload.json) and the runtime [oracle](../../parenthesis_oracle.py). Pinned Go source: [TheAlgorithms/Go `parenthesis.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/strings/parenthesis/parenthesis.go); pinned C source: [TheAlgorithms/C `parenthesis.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/stack/parenthesis.c).

| Language | Port |
|---|---|
| C | [`c/p/parenthesis.c`](../../../c/p/parenthesis.c) |
| C3 | [`c3/p/parenthesis.c3`](../../../c3/p/parenthesis.c3) |
| C++ | [`cpp/p/parenthesis.cpp`](../../../cpp/p/parenthesis.cpp) |
| Elisa | [`elisa/p/parenthesis.elisa`](../../../elisa/p/parenthesis.elisa) |
| Nim | [`nim/p/parenthesis.nim`](../../../nim/p/parenthesis.nim) |
| Odin | [`odin/p/parenthesis.odin`](../../../odin/p/parenthesis.odin) |
| Rust | [`rust/p/parenthesis.rs`](../../../rust/p/parenthesis.rs) |
| V | [`v/p/parenthesis.v`](../../../v/p/parenthesis.v) |
| Zig | [`zig/p/parenthesis.zig`](../../../zig/p/parenthesis.zig) |
