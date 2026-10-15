# Recursive find maximum

## Contract

Find the largest value in a nonempty array with a divide-and-conquer recurrence. Split each inclusive index range at its midpoint, recursively find the maximum of both halves, and return the larger result. The recurrence has `O(n)` total comparisons and `O(log n)` call-stack depth.

Inputs contain 1 through 256 signed 32-bit integers. The result is the maximum value; empty or oversized input returns `-1`. Since `-1` is also a valid maximum, callers use the input length to distinguish that result from invalid input.

The shared ABI is `int64_t find_max_recursion(const int64_t *values, size_t length)`. The Dart and Java sources accept explicit subrange bounds, and JavaScript validates them; this benchmark applies the routines to the full array. The JavaScript source returns an undefined value for an empty array, while Java throws and Dart assumes a nonempty range; the benchmark uses the documented `-1` invalid-input result.

## Workload

[`workload.json`](workload.json) covers singleton arrays, ordered arrays, duplicate maxima, negative values, midpoint boundaries, invalid empty input, and the maximum input length.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/find_max_recursion.c`](../../../c/f/find_max_recursion.c) |
| C3 | [`c3/f/find_max_recursion.c3`](../../../c3/f/find_max_recursion.c3) |
| C++ | [`cpp/f/find_max_recursion.cpp`](../../../cpp/f/find_max_recursion.cpp) |
| Elisa | [`elisa/f/find_max_recursion.elisa`](../../../elisa/f/find_max_recursion.elisa) |
| Nim | [`nim/f/find_max_recursion.nim`](../../../nim/f/find_max_recursion.nim) |
| Odin | [`odin/f/find_max_recursion.odin`](../../../odin/f/find_max_recursion.odin) |
| Rust | [`rust/f/find_max_recursion.rs`](../../../rust/f/find_max_recursion.rs) |
| V | [`v/f/find_max_recursion.v`](../../../v/f/find_max_recursion.v) |
| Zig | [`zig/f/find_max_recursion.zig`](../../../zig/f/find_max_recursion.zig) |

## Upstream references

- [Dart `find_max_recursion.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/maths/find_max_recursion.dart)
- [Java `FindMaxRecursion.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/FindMaxRecursion.java)
- [JavaScript `FindMaxRecursion.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/FindMaxRecursion.js)
