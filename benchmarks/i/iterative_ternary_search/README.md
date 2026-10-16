# Iterative ternary search

## Contract

Search an ascending sequence of signed 32-bit integers for a signed 32-bit target. Return an index containing the target, or `-1` when no match exists. The workload packs the target in the first input slot and the sorted sequence after it; a one-slot input represents an empty sequence.

The implementation preserves the pinned Java source's interval updates: it checks both active endpoints while `right > left`, computes `leftThird = left + (right - left) / 3 + 1` and `rightThird = right - (right - left) / 3 - 1`, then moves `left` when `array[leftThird] <= target` and otherwise moves `right`. A singleton input sequence has the explicit equality check from the source. Duplicate values are allowed and any matching index is acceptable, though the source returns an endpoint as soon as it finds one.

Each language exports a C ABI function with this packed-array signature:

```c
int64_t iterative_ternary_search(const int64_t *packed, size_t length);
```

## Workload

The machine-readable cases are in [`workload.json`](workload.json). They cover empty, singleton, two-element, multi-element, hit, and miss searches. The source-derived expected result follows the exact interval updates above. Timing and result checks are handled by [`benchmarks/run_i64_array_scalar.py`](../../run_i64_array_scalar.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/i/iterative_ternary_search.c`](../../../c/i/iterative_ternary_search.c) |
| C3 | [`c3/i/iterative_ternary_search.c3`](../../../c3/i/iterative_ternary_search.c3) |
| C++ | [`cpp/i/iterative_ternary_search.cpp`](../../../cpp/i/iterative_ternary_search.cpp) |
| Elisa | [`elisa/i/iterative_ternary_search.elisa`](../../../elisa/i/iterative_ternary_search.elisa) |
| Nim | [`nim/i/iterative_ternary_search.nim`](../../../nim/i/iterative_ternary_search.nim) |
| Odin | [`odin/i/iterative_ternary_search.odin`](../../../odin/i/iterative_ternary_search.odin) |
| Rust | [`rust/i/iterative_ternary_search.rs`](../../../rust/i/iterative_ternary_search.rs) |
| V | [`v/i/iterative_ternary_search.v`](../../../v/i/iterative_ternary_search.v) |
| Zig | [`zig/i/iterative_ternary_search.zig`](../../../zig/i/iterative_ternary_search.zig) |

## TheAlgorithms reference

- [Java `IterativeTernarySearch.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/searches/IterativeTernarySearch.java)
