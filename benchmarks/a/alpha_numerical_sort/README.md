# Alpha numerical sort comparator

Compare two lowercase alphanumeric strings in natural order, treating each run of digits as one nonnegative integer.

## Contract

- The `i64_array_scalar` ABI accepts `[lengthA, lengthB, bytesA..., bytesB...]` and returns `-1` when A sorts first, `0` for equal strings, and `1` when B sorts first.
- Each string has 0 through 64 characters from `0` through `9` and `a` through `z`.
- Every digit run is canonical: a run may be exactly `0`, but a longer run cannot begin with `0`. This makes numeric-token comparisons unambiguous.
- Malformed packed input returns `-2`.
- The benchmark compares the comparator sign exactly.

## Source semantics

This adapts pinned [TheAlgorithms JavaScript `AlphaNumericalSort.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Sorts/AlphaNumericalSort.js), which uses `localeCompare` with `{ numeric: true }`. The shared contract focuses on lowercase ASCII letters and canonical decimal runs, avoiding host-locale and leading-zero tie behavior while preserving its natural ordering intent. It benchmarks the comparator itself; callers can use its result to sort a collection.

## Workload

[`workload.json`](workload.json) includes the `z2` versus `z11` example, numeric tokens, prefixes, equality, and invalid inputs.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/alpha_numerical_sort.c`](../../../c/a/alpha_numerical_sort.c) |
| C3 | [`c3/a/alpha_numerical_sort.c3`](../../../c3/a/alpha_numerical_sort.c3) |
| C++ | [`cpp/a/alpha_numerical_sort.cpp`](../../../cpp/a/alpha_numerical_sort.cpp) |
| Elisa | [`elisa/a/alpha_numerical_sort.elisa`](../../../elisa/a/alpha_numerical_sort.elisa) |
| Nim | [`nim/a/alpha_numerical_sort.nim`](../../../nim/a/alpha_numerical_sort.nim) |
| Odin | [`odin/a/alpha_numerical_sort.odin`](../../../odin/a/alpha_numerical_sort.odin) |
| Rust | [`rust/a/alpha_numerical_sort.rs`](../../../rust/a/alpha_numerical_sort.rs) |
| V | [`v/a/alpha_numerical_sort.v`](../../../v/a/alpha_numerical_sort.v) |
| Zig | [`zig/a/alpha_numerical_sort.zig`](../../../zig/a/alpha_numerical_sort.zig) |

The package uses the `i64_array_scalar` benchmark ABI.
