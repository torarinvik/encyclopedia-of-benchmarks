# Recursive binary search

## Contract

Search an ascending sorted sequence of signed 64-bit integers. Return any index containing the target, or `-1` if it is absent. The sequence is read-only; empty input returns `-1`.

Each implementation exports a C ABI function with the algorithm's name:

```c
int64_t recursive_binary_search(const int64_t *values, size_t length, int64_t target);
```

The search is recursive over a half-open range `[low, high)`. Each call checks the midpoint and recurses into the only half that can contain the target. The local contract covers ascending input; the inspected Java reference uses a closed interval and returns an index or `-1`.

## Workload

The workload in [`workload.json`](workload.json) uses unique ascending values `values[index] = 2 * index - length` at lengths `0`, `16`, `1,024`, `65,536`, and `1,048,576`. Nonempty inputs are searched for the first, middle, and last values and a miss (`2,000,001`). Empty input runs only the miss case. Setup and correctness checks happen outside timed samples.

The shared C11 search runner is compiled with `-DBENCHMARK_FUNCTION=recursive_binary_search`. [`benchmarks/run.py`](../../run.py) uses the binary-search comparison model to select repetitions and records JSON Lines matching [`benchmarks/results.schema.json`](../../results.schema.json).

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/r/recursive_binary_search.c`](../../../c/r/recursive_binary_search.c) | Independent portable implementation; TheAlgorithms Java reference below |
| C3 | [`c3/r/recursive_binary_search.c3`](../../../c3/r/recursive_binary_search.c3) | Local port |
| C++ | [`cpp/r/recursive_binary_search.cpp`](../../../cpp/r/recursive_binary_search.cpp) | Local port |
| Elisa | [`elisa/r/recursive_binary_search.elisa`](../../../elisa/r/recursive_binary_search.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/r/recursive_binary_search.nim`](../../../nim/r/recursive_binary_search.nim) | Local port |
| Odin | [`odin/r/recursive_binary_search.odin`](../../../odin/r/recursive_binary_search.odin) | Local port |
| Rust | [`rust/r/recursive_binary_search.rs`](../../../rust/r/recursive_binary_search.rs) | Local port |
| V | [`v/r/recursive_binary_search.v`](../../../v/r/recursive_binary_search.v) | Local port |
| Zig | [`zig/r/recursive_binary_search.zig`](../../../zig/r/recursive_binary_search.zig) | Local port |

All ports use portable recursion and integer index arithmetic; none use CPU-specific instructions or flags.

## TheAlgorithms reference

- [Java `RecursiveBinarySearch.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/searches/RecursiveBinarySearch.java)
