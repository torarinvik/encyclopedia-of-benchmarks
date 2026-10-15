# Generate parentheses

Generate every well-formed sequence containing `n` pairs of parentheses. The shared output order is lexicographic with `(` before `)`; this normalizes the differing traversal orders in the pinned sources.

## Contract

The `i64_array_bytes_output` input is exactly `[n]`, with `1 <= n <= 6`. Each generated sequence has length `2*n`; sequences are concatenated in lexicographic order without separators, so the fixed length makes the output unambiguous. A valid call returns the number of output bytes. Invalid shape or pair count returns `-1`; insufficient capacity or a null output pointer returns `-2`.

## Workload

[`workload.json`](workload.json) covers one through six pairs, invalid shape and bounds, and short output capacity.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/g/generate_parentheses.c`](../../../c/g/generate_parentheses.c) |
| C3 | [`c3/g/generate_parentheses.c3`](../../../c3/g/generate_parentheses.c3) |
| C++ | [`cpp/g/generate_parentheses.cpp`](../../../cpp/g/generate_parentheses.cpp) |
| Elisa | [`elisa/g/generate_parentheses.elisa`](../../../elisa/g/generate_parentheses.elisa) |
| Nim | [`nim/g/generate_parentheses.nim`](../../../nim/g/generate_parentheses.nim) |
| Odin | [`odin/g/generate_parentheses.odin`](../../../odin/g/generate_parentheses.odin) |
| Rust | [`rust/g/generate_parentheses.rs`](../../../rust/g/generate_parentheses.rs) |
| V | [`v/g/generate_parentheses.v`](../../../v/g/generate_parentheses.v) |
| Zig | [`zig/g/generate_parentheses.zig`](../../../zig/g/generate_parentheses.zig) |

## Pinned sources

- C++ [`generate_parentheses.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/backtracking/generate_parentheses.cpp)
- JavaScript [`generateParentheses.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Backtracking/generateParentheses.js)
- Python [`generate_parentheses.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/backtracking/generate_parentheses.py)
