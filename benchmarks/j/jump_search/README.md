# Jump search

## Contract

Search an ascending sorted sequence of signed 64-bit integers. Return an index containing the target, or `-1` if it is absent. Any matching index is valid when duplicates occur. The sequence is read-only; empty input returns `-1`.

The exported C ABI entry point is:

```c
int64_t jump_search(const int64_t *values, size_t length, int64_t target);
```

The local ports use an integer square-root helper to choose the jump width, avoiding an architecture-specific implementation or a separate math-library dependency.

## Workload

See [`workload.json`](workload.json). Each array is strictly ascending and uses `values[index] = 2 * index - length` at lengths `0`, `16`, `1,024`, `65,536`, and `1,048,576`. Hit cases target the first, middle, and last elements. The miss target is `2,000,001`; the empty array runs only this miss case. Data construction and correctness checks are outside timed samples.

The shared search runner uses `-DBENCHMARK_FUNCTION=jump_search`; [`benchmarks/run.py`](../../run.py) estimates the comparisons for each jump block and linear scan, then appends records matching [`benchmarks/results.schema.json`](../../results.schema.json).

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/j/jump_search.c`](../../../c/j/jump_search.c) | Independent portable implementation; TheAlgorithms C reference below |
| C3 | [`c3/j/jump_search.c3`](../../../c3/j/jump_search.c3) | Local port |
| C++ | [`cpp/j/jump_search.cpp`](../../../cpp/j/jump_search.cpp) | Independent portable implementation; TheAlgorithms C++ reference below |
| Elisa | [`elisa/j/jump_search.elisa`](../../../elisa/j/jump_search.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/j/jump_search.nim`](../../../nim/j/jump_search.nim) | Independent portable implementation; TheAlgorithms Nim reference below |
| Odin | [`odin/j/jump_search.odin`](../../../odin/j/jump_search.odin) | Local port |
| Rust | [`rust/j/jump_search.rs`](../../../rust/j/jump_search.rs) | Independent portable implementation; TheAlgorithms Rust reference below |
| V | [`v/j/jump_search.v`](../../../v/j/jump_search.v) | Local port |
| Zig | [`zig/j/jump_search.zig`](../../../zig/j/jump_search.zig) | Local port |

The C and C++ upstream examples use floating-point square root and do not handle empty arrays before indexing. Rust returns an optional index and handles empty input. The local contract makes empty input explicit and uses integer square root.

## TheAlgorithms references

- [C `jump_search.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/searching/jump_search.c)
- [C++ `jump_search.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/search/jump_search.cpp)
- [Rust `jump_search.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/searching/jump_search.rs)
