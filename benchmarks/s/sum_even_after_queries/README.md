# Sum of even numbers after queries

Apply each point update to the current number at its indexed position and report the sum of all even values after that update. Query order matters because each update observes the result of the previous update.

## Contract

- Input is packed as `[number_count, query_count, initial numbers..., (delta, index)...]` in signed 64-bit values.
- Number and query counts are each from 1 through 1,000. Initial values are from 1 through 1,000, update deltas from -1,000 through 1,000, and each index is valid for the number array.
- Return `query_count` and write one signed 32-bit little-endian even sum per query. The input stays read-only; implementations keep the changing values in private working storage.
- Invalid packed input returns `-1`; insufficient output capacity returns `-2`.
- The algorithm computes the initial even sum once, then removes the old value's contribution, applies the update, and adds the new value's contribution for each query. Time is O(n + q); working space is O(n).

## Workload and verification

[`workload.json`](workload.json) includes the published example, repeated and parity-changing updates, negative even sums, boundary values, malformed inputs, and a maximum packed input. [`benchmarks/verify_sum_even_after_queries.py`](../../verify_sum_even_after_queries.py) checks the nine ports against an independent oracle that recomputes the even sum after every update, exhaustive small inputs, and deterministic random workloads.

The benchmark is based on [TheAlgorithms C LeetCode source `985.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/985.c), which maintains the even sum incrementally and emits one sum after each query. The source mutates its `nums` argument; this benchmark preserves the update sequence using private state because the shared call interface treats its input buffer as read-only.

Build with the shared `i64_array_bytes_output` ABI family and record with `benchmarks/run_i64_array_bytes_output.py`.
