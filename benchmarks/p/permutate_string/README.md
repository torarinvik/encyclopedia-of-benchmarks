# String permutations

This benchmark ports the pinned JavaScript `permutate` function. It enumerates the permutations of a string, removes duplicate strings, sorts the result lexicographically, and returns that list.

## Contract

- The scalar-array input is `[length, ASCII byte...]` with 1 to 7 distinct printable ASCII bytes (33 through 126).
- The source rejects empty input. Invalid or out-of-domain input returns `-1` in the benchmark.
- The return value is 32-bit FNV-1a over the sorted permutation strings, with a zero byte after each string. This deterministic serialization maps the source's list result to the scalar-array ABI.
- Restricting characters to distinct printable ASCII keeps the source's duplicate-filter step behavior-neutral and makes JavaScript's sort order agree with bytewise lexicographic order.

The pinned source constructs permutations incrementally by inserting each character at every position, filters duplicate strings, and sorts the result. The portable ports use lexicographic successor enumeration from the sorted input bytes, producing the same ordered list within the benchmark contract before hashing it.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/permutate_string.c`](../../../c/p/permutate_string.c) |
| C3 | [`c3/p/permutate_string.c3`](../../../c3/p/permutate_string.c3) |
| C++ | [`cpp/p/permutate_string.cpp`](../../../cpp/p/permutate_string.cpp) |
| Elisa | [`elisa/p/permutate_string.elisa`](../../../elisa/p/permutate_string.elisa) |
| Nim | [`nim/p/permutate_string.nim`](../../../nim/p/permutate_string.nim) |
| Odin | [`odin/p/permutate_string.odin`](../../../odin/p/permutate_string.odin) |
| Rust | [`rust/p/permutate_string.rs`](../../../rust/p/permutate_string.rs) |
| V | [`v/p/permutate_string.v`](../../../v/p/permutate_string.v) |
| Zig | [`zig/p/permutate_string.zig`](../../../zig/p/permutate_string.zig) |

## Workload and recording

[`workload.json`](workload.json) includes one- through seven-character inputs, unsorted input, and invalid-domain cases. The runtime oracle is [`permutate_string_oracle.py`](../../permutate_string_oracle.py); the shared array-scalar runner checks expected hashes before recording.

## Pinned source

- [TheAlgorithms/JavaScript `PermutateString.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/String/PermutateString.js)
