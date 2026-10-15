# Binary search

## Contract

Search an ascending sorted sequence of signed 64-bit integers for a signed 64-bit target. Return the index of a matching element, or `-1` when no match exists. If duplicates are present, any matching index is valid. The sequence is read-only, and an empty sequence returns `-1`.

Each language exports a C ABI function with the algorithm's name:

```c
int64_t binary_search(const int64_t *values, size_t length, int64_t target);
```

The input pointer is non-null even when `length` is zero. Benchmark values are unique, so every hit case has one expected index.

## Workload

The machine-readable workload is in [`workload.json`](workload.json). Each input is generated in ascending order with `values[index] = 2 * index - length`, for lengths `0`, `16`, `1,024`, `65,536`, and `1,048,576`. This gives distinct values and keeps generation outside the timed section.

For nonempty inputs, run first, middle, and last hits, plus a miss for `2,000,001`. For the empty input, run only the miss case. Targets and expected indices are derived from the generated sequence. Sorting is not timed.

The shared C11 search runner in [`benchmarks/harness/runner.c`](../../harness/runner.c) is compiled with `-DBENCHMARK_FUNCTION=binary_search`. The JSONL recorder in [`benchmarks/run.py`](../../run.py) selects repetitions from the workload's `binary_search` comparison model. Results follow the common [`benchmarks/results.schema.json`](../../results.schema.json) schema.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/b/binary_search.c`](../../../c/b/binary_search.c) | Independent portable implementation; TheAlgorithms C reference below |
| C3 | [`c3/b/binary_search.c3`](../../../c3/b/binary_search.c3) | Local port |
| C++ | [`cpp/b/binary_search.cpp`](../../../cpp/b/binary_search.cpp) | Independent portable implementation; TheAlgorithms C++ reference below |
| Elisa | [`elisa/b/binary_search.elisa`](../../../elisa/b/binary_search.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/b/binary_search.nim`](../../../nim/b/binary_search.nim) | Independent portable implementation; TheAlgorithms Nim reference below |
| Odin | [`odin/b/binary_search.odin`](../../../odin/b/binary_search.odin) | Local port |
| Rust | [`rust/b/binary_search.rs`](../../../rust/b/binary_search.rs) | Independent portable implementation; TheAlgorithms Rust reference below |
| V | [`v/b/binary_search.v`](../../../v/b/binary_search.v) | Local port |
| Zig | [`zig/b/binary_search.zig`](../../../zig/b/binary_search.zig) | Local port |

The inspected upstream implementations differ in API and scope: the C file includes recursive and iterative forms, Nim returns an optional position, Rust also handles descending order, and the C++ function takes its vector by value. The local contract standardizes ascending `i64` input and an index-or-`-1` result. Local code was written independently.

## TheAlgorithms references

The source paths below were checked at the pinned commits listed in the catalog:

- [C `binary_search.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/searching/binary_search.c)
- [C++ `binary_search.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/search/binary_search.cpp)
- [Nim `binary_search.nim`](https://github.com/TheAlgorithms/Nim/blob/63eec16614b46c91078653e8d3c049fe99ad36b3/searches/binary_search.nim)
- [Rust `binary_search.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/searching/binary_search.rs)
- [C `other_binary_search.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/searching/other_binary_search.c)
- [C# `BinarySearcher.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Search/BinarySearcher.cs)
