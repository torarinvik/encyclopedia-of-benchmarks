# Recursive find minimum

## Contract

Find the smallest value in a nonempty array with divide and conquer. Split each inclusive index range at its midpoint, recursively find the minimum of both halves, and return the smaller result. The recurrence takes `O(n)` comparisons with `O(log n)` call-stack depth.

Inputs contain 1 through 256 signed 32-bit integers. The result is the minimum; empty or oversized input returns `-1`. Since `-1` is a valid minimum, callers use the input length to distinguish it from invalid input.

The shared ABI is `int64_t find_min_recursion(const int64_t *values, size_t length)`. The pinned Dart and Java sources accept explicit subrange bounds and operate on nonempty arrays; this benchmark applies the recurrence to the full array and uses the same invalid-input sentinel as the local benchmark family.

## Workload

[`workload.json`](workload.json) covers singleton arrays, ordered arrays, duplicate minima, all-positive and all-negative arrays, midpoint boundaries, empty input, and the maximum length.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/find_min_recursion.c`](../../../c/f/find_min_recursion.c) |
| C3 | [`c3/f/find_min_recursion.c3`](../../../c3/f/find_min_recursion.c3) |
| C++ | [`cpp/f/find_min_recursion.cpp`](../../../cpp/f/find_min_recursion.cpp) |
| Elisa | [`elisa/f/find_min_recursion.elisa`](../../../elisa/f/find_min_recursion.elisa) |
| Nim | [`nim/f/find_min_recursion.nim`](../../../nim/f/find_min_recursion.nim) |
| Odin | [`odin/f/find_min_recursion.odin`](../../../odin/f/find_min_recursion.odin) |
| Rust | [`rust/f/find_min_recursion.rs`](../../../rust/f/find_min_recursion.rs) |
| V | [`v/f/find_min_recursion.v`](../../../v/f/find_min_recursion.v) |
| Zig | [`zig/f/find_min_recursion.zig`](../../../zig/f/find_min_recursion.zig) |

## Upstream references

- [Dart `find_min_recursion.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/maths/find_min_recursion.dart)
- [Java `FindMinRecursion.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/FindMinRecursion.java)

The source-backed oracle is implemented in [`benchmarks/run_i64_array_scalar.py`](../../run_i64_array_scalar.py). Build with the i64_array_scalar ABI family and record with that runner.
