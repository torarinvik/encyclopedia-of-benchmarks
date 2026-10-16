# Insert and delete array elements

Port the pinned Java helpers that insert an integer at a position or delete an element, producing a new array with the remaining elements shifted.

## Contract

The `i64_array_bytes_output` ABI accepts `[operation, length, position, element, values...]`. Operation `0` inserts `element` at a 0-based position in `0..length`; operation `1` removes the element at a position in `0..length-1` and requires the unused element field to be zero. Array length is 0–256, and values are signed 32-bit integers. Results are returned as little-endian signed 32-bit values. Invalid inputs return `-1`; insufficient output capacity returns `-2`. Both operations run in O(n) time and use output storage proportional to the resulting array. The input array is not modified.

[`workload.json`](workload.json) covers insertion at each boundary, deletion at each boundary, invalid positions, the empty/singleton cases, and insufficient capacity.

Pinned source: [TheAlgorithms/Java `InsertDeleteInArray.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/others/InsertDeleteInArray.java). The interactive `main` method is omitted; the benchmark ports `insertElement` and `deleteElement`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/i/insert_delete_in_array.c`](../../../c/i/insert_delete_in_array.c) |
| C3 | [`c3/i/insert_delete_in_array.c3`](../../../c3/i/insert_delete_in_array.c3) |
| C++ | [`cpp/i/insert_delete_in_array.cpp`](../../../cpp/i/insert_delete_in_array.cpp) |
| Elisa | [`elisa/i/insert_delete_in_array.elisa`](../../../elisa/i/insert_delete_in_array.elisa) |
| Nim | [`nim/i/insert_delete_in_array.nim`](../../../nim/i/insert_delete_in_array.nim) |
| Odin | [`odin/i/insert_delete_in_array.odin`](../../../odin/i/insert_delete_in_array.odin) |
| Rust | [`rust/i/insert_delete_in_array.rs`](../../../rust/i/insert_delete_in_array.rs) |
| V | [`v/i/insert_delete_in_array.v`](../../../v/i/insert_delete_in_array.v) |
| Zig | [`zig/i/insert_delete_in_array.zig`](../../../zig/i/insert_delete_in_array.zig) |
