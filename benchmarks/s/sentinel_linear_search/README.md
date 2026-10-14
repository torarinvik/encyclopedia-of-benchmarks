# Sentinel linear search

## Contract

Search a mutable sequence of signed 64-bit integers and return any matching index, or `-1` if the target is absent. Empty input returns `-1`. The algorithm temporarily replaces the last element with the target, then restores the saved value before returning. The runner reuses the same buffer for repeated calls.

The exported function has this mutable C ABI:

```c
int64_t sentinel_linear_search(int64_t *values, size_t length, int64_t target);
```

Compile the common runner with `-DBENCHMARK_FUNCTION=sentinel_linear_search -DBENCHMARK_MUTABLE_INPUT` to select the mutable-pointer ABI. No architecture-specific intrinsics or compiler flags are required.

## Workload

See [`workload.json`](workload.json). The deterministic ascending input uses `values[index] = 2 * index - length` at lengths `0`, `16`, `1,024`, `65,536`, and `1,048,576`. Nonempty inputs are searched for the first, middle, and last values, plus a miss (`2,000,001`). Empty input runs only the miss case. The runner initializes input and checks results outside timed samples.

[`benchmarks/run.py`](../../run.py) uses the sentinel search's comparison model: a last-element hit takes one data comparison, other hits take the initial last-element check plus the scan through the match, and a miss scans through the installed sentinel. The result records conform to [`benchmarks/results.schema.json`](../../results.schema.json).

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/s/sentinel_linear_search.c`](../../../c/s/sentinel_linear_search.c) | Independent portable implementation; TheAlgorithms C reference below |
| C3 | [`c3/s/sentinel_linear_search.c3`](../../../c3/s/sentinel_linear_search.c3) | Local port |
| C++ | [`cpp/s/sentinel_linear_search.cpp`](../../../cpp/s/sentinel_linear_search.cpp) | Local port |
| Elisa | [`elisa/s/sentinel_linear_search.elisa`](../../../elisa/s/sentinel_linear_search.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/s/sentinel_linear_search.nim`](../../../nim/s/sentinel_linear_search.nim) | Local port |
| Odin | [`odin/s/sentinel_linear_search.odin`](../../../odin/s/sentinel_linear_search.odin) | Local port |
| Rust | [`rust/s/sentinel_linear_search.rs`](../../../rust/s/sentinel_linear_search.rs) | Local port |
| V | [`v/s/sentinel_linear_search.v`](../../../v/s/sentinel_linear_search.v) | Local port |
| Zig | [`zig/s/sentinel_linear_search.zig`](../../../zig/s/sentinel_linear_search.zig) | Local port |

The inspected upstream C implementation mutates the final array slot and does not handle empty input before indexing. The Java and Python versions also use a sentinel but differ in their APIs and mutation details. The local contract makes empty input explicit and restores the buffer after each call.

## TheAlgorithms references

- [C `sentinel_linear_search.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/searching/sentinel_linear_search.c)
- [Java `SentinelLinearSearch.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/searches/SentinelLinearSearch.java)
- [Python `sentinel_linear_search.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/searches/sentinel_linear_search.py)
