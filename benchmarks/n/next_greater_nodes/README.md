# Next greater node values

For each singly linked-list value, find the first later value that is strictly greater. The pinned C implementation uses a forward scan from each position, so this benchmark preserves its quadratic search pattern in all nine languages.

## Contract

- The input array represents linked-list values in head-to-tail order. Its length is 1 through 4,096; values are in `[1, 1,000,000,000]`, matching the source problem's positive-value domain.
- Write one signed 32-bit little-endian result per input value. The result is the first greater value to its right, or zero when none exists. Equal values are not greater.
- Return the node count on success, `-1` for an invalid length or value, and `-2` when the output buffer is smaller than four bytes per node. Capacity failures leave the output unchanged.

## Workload and verification

[`workload.json`](workload.json) includes increasing, decreasing, repeated, maximum-value, and 4,096-node inputs. [`benchmarks/verify_next_greater_nodes.py`](../../verify_next_greater_nodes.py) checks the nine ports against an independent monotonic-stack oracle, exhaustively checks short value sequences, uses deterministic full-range inputs, and checks invalid inputs and insufficient output capacity.

The benchmark is based on [TheAlgorithms C LeetCode source `1019.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/1019.c). The source allocates zero-filled output and scans the remaining list for each node; the shared contract uses caller-owned storage and explicitly handles an empty input as invalid.

Build with the `i64_array_bytes_output` ABI family and record with `benchmarks/run_i64_array_bytes_output.py`.
