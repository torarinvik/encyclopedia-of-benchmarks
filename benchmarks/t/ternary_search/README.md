# Ternary search

## Contract

Search an ascending sorted sequence of signed 64-bit integers. Return any index containing the target, or `-1` when it is absent. The input is read-only; an empty sequence returns `-1`.

Each language exports a C ABI function with the algorithm's name:

```c
int64_t ternary_search(const int64_t *values, size_t length, int64_t target);
```

The implementation probes the two interior positions that divide the active half-open range into thirds, then discards the portions that cannot contain the target. Integer index arithmetic keeps the baseline portable across target architectures.

## Workload

The machine-readable workload is in [`workload.json`](workload.json). It generates `values[index] = 2 * index - length` at lengths `0`, `16`, `1,024`, `65,536`, and `1,048,576`. For nonempty inputs, the cases search for the first, middle, and last values and a miss (`2,000,001`). The empty input runs only the miss case. Setup and correctness checks stay outside timed samples.

The shared C11 search runner is compiled with `-DBENCHMARK_FUNCTION=ternary_search`. [`benchmarks/run.py`](../../run.py) models the two probe equalities and the subsequent range comparisons to select repetitions, then writes records matching [`benchmarks/results.schema.json`](../../results.schema.json).

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/t/ternary_search.c`](../../../c/t/ternary_search.c) | Independent portable implementation; TheAlgorithms C reference below |
| C3 | [`c3/t/ternary_search.c3`](../../../c3/t/ternary_search.c3) | Local port |
| C++ | [`cpp/t/ternary_search.cpp`](../../../cpp/t/ternary_search.cpp) | Independent portable implementation; TheAlgorithms C++ reference below |
| Elisa | [`elisa/t/ternary_search.elisa`](../../../elisa/t/ternary_search.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/t/ternary_search.nim`](../../../nim/t/ternary_search.nim) | Local port |
| Odin | [`odin/t/ternary_search.odin`](../../../odin/t/ternary_search.odin) | Local port |
| Rust | [`rust/t/ternary_search.rs`](../../../rust/t/ternary_search.rs) | Independent portable implementation; TheAlgorithms Rust reference below |
| V | [`v/t/ternary_search.v`](../../../v/t/ternary_search.v) | Local port |
| Zig | [`zig/t/ternary_search.zig`](../../../zig/t/ternary_search.zig) | Local port |

The inspected upstream C version is recursive, C++ includes a precision-based variant, and Rust returns an optional index. These local versions use the same exact-search contract in every language.

## TheAlgorithms references

- [C `ternary_search.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/searching/ternary_search.c)
- [C++ `ternary_search.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/search/ternary_search.cpp)
- [Rust `ternary_search.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74a939ec5163648458a8c2b46fd4c/src/searching/ternary_search.rs)
