# Exponential search

## Contract

Search an ascending sorted sequence of signed 64-bit integers for a signed 64-bit target. Find an index containing the target or return `-1` if it is absent. If duplicate values are present, any matching index is valid. The input is read-only; an empty sequence returns `-1`.

Each language exports a C ABI function with the algorithm's name:

```c
int64_t exponential_search(const int64_t *values, size_t length, int64_t target);
```

The exponential range growth and subsequent binary search are both timed. The input pointer is non-null for empty input, though the function must not dereference it when the length is zero.

## Workload

The machine-readable workload is in [`workload.json`](workload.json). Generate an ascending unique sequence with `values[index] = 2 * index - length` at lengths `0`, `16`, `1,024`, `65,536`, and `1,048,576`. For nonempty lengths, search for the first, middle, and last value and for a miss (`2,000,001`). For length zero, run only the miss case. Input setup and result checks happen outside timed samples.

The shared C11 search runner in [`benchmarks/harness/runner.c`](../../harness/runner.c) is compiled with `-DBENCHMARK_FUNCTION=exponential_search`. The recorder applies the exponential search comparison model to choose repetitions and writes JSONL records conforming to [`benchmarks/results.schema.json`](../../results.schema.json).

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/e/exponential_search.c`](../../../c/e/exponential_search.c) | Independent portable implementation; TheAlgorithms C reference below |
| C3 | [`c3/e/exponential_search.c3`](../../../c3/e/exponential_search.c3) | Local port |
| C++ | [`cpp/e/exponential_search.cpp`](../../../cpp/e/exponential_search.cpp) | Independent portable implementation; TheAlgorithms C++ reference below |
| Elisa | [`elisa/e/exponential_search.elisa`](../../../elisa/e/exponential_search.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/e/exponential_search.nim`](../../../nim/e/exponential_search.nim) | Independent portable implementation; TheAlgorithms Nim reference below |
| Odin | [`odin/e/exponential_search.odin`](../../../odin/e/exponential_search.odin) | Local port |
| Rust | [`rust/e/exponential_search.rs`](../../../rust/e/exponential_search.rs) | Independent portable implementation; TheAlgorithms Rust reference below |
| V | [`v/e/exponential_search.v`](../../../v/e/exponential_search.v) | Local port |
| Zig | [`zig/e/exponential_search.zig`](../../../zig/e/exponential_search.zig) | Local port |

The inspected upstream sources use different APIs and range-search details. The C implementation uses a 16-bit length and an exponential bound probe; C++ calls its approach Struzik search and returns a pointer; Rust returns an optional index. Local ports were written independently against the shared contract.

## TheAlgorithms references

These paths were checked at the pinned source commits:

- [C `exponential_search.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/searching/exponential_search.c)
- [C++ `exponential_search.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/search/exponential_search.cpp)
- [Rust `exponential_search.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/searching/exponential_search.rs)
