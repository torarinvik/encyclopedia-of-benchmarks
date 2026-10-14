# Fibonacci search

## Contract

Search an ascending sorted sequence of signed 64-bit integers. Return an index containing the target, or `-1` if it is absent. Any matching index is valid when duplicates occur. The sequence is read-only; empty input returns `-1`.

The exported C ABI entry point is:

```c
int64_t fibonacci_search(const int64_t *values, size_t length, int64_t target);
```

## Workload

See [`workload.json`](workload.json). Each array is strictly ascending with `values[index] = 2 * index - length` at lengths `0`, `16`, `1,024`, `65,536`, and `1,048,576`. Run first, middle, and last hits plus a miss for `2,000,001`; the empty sequence runs only the miss. Input creation and correctness validation are outside timed samples.

The shared runner uses `-DBENCHMARK_FUNCTION=fibonacci_search`. The JSONL recorder models each Fibonacci probe and the final-element check when selecting repetitions. Results use [`benchmarks/results.schema.json`](../../results.schema.json).

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/f/fibonacci_search.c`](../../../c/f/fibonacci_search.c) | Independent portable implementation; TheAlgorithms C reference below |
| C3 | [`c3/f/fibonacci_search.c3`](../../../c3/f/fibonacci_search.c3) | Local port |
| C++ | [`cpp/f/fibonacci_search.cpp`](../../../cpp/f/fibonacci_search.cpp) | Independent portable implementation; TheAlgorithms C++ reference below |
| Elisa | [`elisa/f/fibonacci_search.elisa`](../../../elisa/f/fibonacci_search.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/f/fibonacci_search.nim`](../../../nim/f/fibonacci_search.nim) | Local port |
| Odin | [`odin/f/fibonacci_search.odin`](../../../odin/f/fibonacci_search.odin) | Local port |
| Rust | [`rust/f/fibonacci_search.rs`](../../../rust/f/fibonacci_search.rs) | Independent portable implementation; TheAlgorithms Rust reference below |
| V | [`v/f/fibonacci_search.v`](../../../v/f/fibonacci_search.v) | Local port |
| Zig | [`zig/f/fibonacci_search.zig`](../../../zig/f/fibonacci_search.zig) | Local port |

The inspected upstream sources use fixed-width signed indices, vector APIs, or optional indices. The local ports share the same signed 64-bit result and handle the empty sequence before computing probes. Local code was written independently.

## TheAlgorithms references

- [C `fibonacci_search.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/searching/fibonacci_search.c)
- [C++ `fibonacci_search.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/search/fibonacci_search.cpp)
- [Rust `fibonacci_search.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/searching/fibonacci_search.rs)
