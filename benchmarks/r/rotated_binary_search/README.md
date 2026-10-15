# Rotated binary search

Search for a key in a nondecreasing array rotated at an unknown pivot. When duplicates make the sorted half ambiguous, shrink both ends; otherwise follow the sorted half. The search returns the first midpoint match encountered, which may be any matching index when duplicates exist.

## Contract

- The `i64_array_scalar` ABI accepts `[count, values..., key]` and returns an index containing the key.
- There are 0 through 256 values, all signed 32-bit. Values must be nondecreasing before one rotation; duplicates are allowed.
- Return `-1` for an empty array or absent key. Malformed input, values outside signed 32-bit, or arrays outside the rotated-sorted domain return `-2`.
- Duplicate matches follow the same midpoint and ambiguity rules as the pinned Java source.
- Results are compared exactly.

## Source semantics

This follows [TheAlgorithms Java `RotatedBinarySearch.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/searches/RotatedBinarySearch.java). The benchmark adds bounded packed-input validation and checks that each array belongs to the rotated-sorted domain before running the same search loop.

## Workload

[`workload.json`](workload.json) covers empty/singleton arrays, found and absent keys, duplicate ambiguity, invalid rotation, malformed length, and values outside signed 32-bit.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/rotated_binary_search.c`](../../../c/r/rotated_binary_search.c) |
| C3 | [`c3/r/rotated_binary_search.c3`](../../../c3/r/rotated_binary_search.c3) |
| C++ | [`cpp/r/rotated_binary_search.cpp`](../../../cpp/r/rotated_binary_search.cpp) |
| Elisa | [`elisa/r/rotated_binary_search.elisa`](../../../elisa/r/rotated_binary_search.elisa) |
| Nim | [`nim/r/rotated_binary_search.nim`](../../../nim/r/rotated_binary_search.nim) |
| Odin | [`odin/r/rotated_binary_search.odin`](../../../odin/r/rotated_binary_search.odin) |
| Rust | [`rust/r/rotated_binary_search.rs`](../../../rust/r/rotated_binary_search.rs) |
| V | [`v/r/rotated_binary_search.v`](../../../v/r/rotated_binary_search.v) |
| Zig | [`zig/r/rotated_binary_search.zig`](../../../zig/r/rotated_binary_search.zig) |

The package uses the `i64_array_scalar` benchmark ABI.
