# Interpolation search

## Contract

Search a strictly ascending sequence of signed 64-bit integers for a signed 64-bit target. Return an index containing the target, or `-1` if it is absent. The input is read-only, and an empty sequence returns `-1`. Inputs must be ordered and keep the interpolation numerator `(target - values[low]) * (high - low)` within signed 64-bit range; the declared workload satisfies that arithmetic bound.

The exported C ABI entry point is:

```c
int64_t interpolation_search(const int64_t *values, size_t length, int64_t target);
```

## Workload

See [`workload.json`](workload.json). Each array uses `values[index] = 2 * index - length`, producing strictly ascending unique values at lengths `0`, `16`, `1,024`, `65,536`, and `1,048,576`. Search first, middle, and last hits and a miss for `2,000,001`; run only the miss case for empty input. The evenly spaced inputs make the interpolation estimate useful while keeping all arithmetic within the declared bound.

The shared search runner is compiled with `-DBENCHMARK_FUNCTION=interpolation_search`. The recorder applies an interpolation-search comparison model and emits JSONL results using [`benchmarks/results.schema.json`](../../results.schema.json).

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/i/interpolation_search.c`](../../../c/i/interpolation_search.c) | Independent portable implementation; TheAlgorithms C reference below |
| C3 | [`c3/i/interpolation_search.c3`](../../../c3/i/interpolation_search.c3) | Local port |
| C++ | [`cpp/i/interpolation_search.cpp`](../../../cpp/i/interpolation_search.cpp) | Independent portable implementation; TheAlgorithms C++ reference below |
| Elisa | [`elisa/i/interpolation_search.elisa`](../../../elisa/i/interpolation_search.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/i/interpolation_search.nim`](../../../nim/i/interpolation_search.nim) | Local port |
| Odin | [`odin/i/interpolation_search.odin`](../../../odin/i/interpolation_search.odin) | Local port |
| Rust | [`rust/i/interpolation_search.rs`](../../../rust/i/interpolation_search.rs) | Independent portable implementation; TheAlgorithms Rust reference below |
| V | [`v/i/interpolation_search.v`](../../../v/i/interpolation_search.v) | Local port |
| Zig | [`zig/i/interpolation_search.zig`](../../../zig/i/interpolation_search.zig) | Local port |

The inspected sources use different integer widths and result APIs. The local benchmark standardizes the ascending signed 64-bit input and `-1` miss result; its workload keeps the arithmetic in range. Local sources were written independently.

## TheAlgorithms references

- [C `interpolation_search.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/searching/interpolation_search.c)
- [C++ `interpolation_search.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/search/interpolation_search.cpp)
- [Rust `interpolation_search.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/searching/interpolation_search.rs)
