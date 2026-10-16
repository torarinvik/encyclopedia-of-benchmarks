# Sentinel search

## Review

The pinned PHP and TypeScript implementations both save the array's final element, place the target there as a sentinel, scan without checking the length on each iteration, restore the original final element, and return an index only when the scan stopped before the sentinel. TypeScript explicitly returns `null` for empty input; PHP indexes `-1` on an empty array. The local contract gives empty input a defined `-1` result and standardizes both source result conventions to a signed index. The PHP implementation uses loose equality while TypeScript uses strict equality; this benchmark uses only signed 64-bit integer values, so their comparison behavior agrees. The TypeScript comment calls the array sorted, but the algorithm itself does not require sorted input.

## Contract

The function uses a mutable signed 64-bit array and the shared search ABI:

```c
int64_t sentinel_search(int64_t *values, size_t length, int64_t target);
```

Return the first matching index or `-1` if absent. Empty input returns `-1`. For a nonempty input, save the last value, return the last index immediately when it already matches, otherwise install the target at the last index, scan until a match, restore the saved value, and return the index only if it precedes the last slot. The array is restored before the function returns. The benchmark's ascending generated values are distinct; the contract also specifies first-match behavior for duplicates.

## Workload

[`workload.json`](workload.json) uses ascending arrays of lengths 0, 16, 1,024, 65,536, and 1,048,576, then searches for first, middle, and last values and a fixed absent value. The empty input is tested for a miss only. Compile [`benchmarks/harness/runner.c`](../../harness/runner.c) with `-DBENCHMARK_FUNCTION=sentinel_search -DBENCHMARK_MUTABLE_INPUT`; [`benchmarks/run.py`](../../run.py) uses the `sentinel_linear_scan` comparison model to choose repetitions. The independent bounded oracle is [`sentinel_search_oracle.py`](../../sentinel_search_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/sentinel_search.c`](../../../c/s/sentinel_search.c) |
| C3 | [`c3/s/sentinel_search.c3`](../../../c3/s/sentinel_search.c3) |
| C++ | [`cpp/s/sentinel_search.cpp`](../../../cpp/s/sentinel_search.cpp) |
| Elisa | [`elisa/s/sentinel_search.elisa`](../../../elisa/s/sentinel_search.elisa) |
| Nim | [`nim/s/sentinel_search.nim`](../../../nim/s/sentinel_search.nim) |
| Odin | [`odin/s/sentinel_search.odin`](../../../odin/s/sentinel_search.odin) |
| Rust | [`rust/s/sentinel_search.rs`](../../../rust/s/sentinel_search.rs) |
| V | [`v/s/sentinel_search.v`](../../../v/s/sentinel_search.v) |
| Zig | [`zig/s/sentinel_search.zig`](../../../zig/s/sentinel_search.zig) |

## TheAlgorithms references

- [PHP `SentinelSearch.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Searches/SentinelSearch.php)
- [TypeScript `sentinel_search.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/search/sentinel_search.ts)
