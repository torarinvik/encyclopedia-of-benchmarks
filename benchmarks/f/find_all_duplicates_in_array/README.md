# Find all duplicates in an array

This benchmark returns each value that occurs twice in an integer array. The duplicate values are returned in ascending order.

## Contract

- Input is a read-only array of signed 64-bit integers with length from 0 to 100,000.
- For a nonempty array of length `n`, every value must be in `[1, n]`, and each value may occur at most twice.
- The empty array returns zero results. Invalid inputs return `-1`.
- If the output buffer is too small, the function returns `-2` without writing output.
- On success, each duplicated value appears once in the output, encoded as a little-endian signed 32-bit integer. Duplicate values are sorted ascending; the returned integer is the number of output values.

## Upstream review

The pinned C candidate uses `qsort` and scans neighboring values, emitting each matching pair once. Its problem contract guarantees values in `[1, n]` and at most two occurrences per value. This benchmark keeps those constraints explicit, rejects malformed inputs, and uses a caller-owned output buffer so the input remains unchanged. Source: [TheAlgorithms/C, 442.c](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/442.c).

## Implementations

The nine portable implementations sort a bounded copy and scan equal-value runs. C uses `qsort`; the other ports use a bounded heap sort or their language's native sort. They use O(n log n) time and O(n) additional storage.

## Workload and verification

`workload.json` covers empty and duplicate-free arrays, the published example, multiple and maximum-size duplicate groups, invalid values, a value occurring more than twice, and an overlong input. `benchmarks/verify_find_all_duplicates_in_array.py` checks exhaustive valid short arrays, deterministic random cases, contract boundaries, and every workload record in all nine languages.

Build and record with the `i64_array_bytes_output` ABI family and `benchmarks/run_i64_array_bytes_output.py`.
