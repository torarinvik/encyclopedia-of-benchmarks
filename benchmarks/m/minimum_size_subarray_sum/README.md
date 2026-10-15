# Minimum Size Subarray Sum

Find the shortest contiguous range whose sum is at least a target. The implementation follows the pinned source's sliding window: it scans values from left to right and repeatedly removes the leftmost value while the current sum still meets the target.

## Contract

- The read-only signed 64-bit input packs `[target, count, value_0, ..., value_(count-1)]`.
- `target` is in `1..1,000,000`; `count` is in `0..256`; each value is in `1..1,000,000`.
- The packed array must contain exactly `count + 2` values.
- Return the minimum qualifying subarray length. Return `0` when the array is empty or no range reaches the target. Malformed or out-of-domain input returns `-1`.
- Values are positive so the source's sliding-window shrinking rule is valid for every benchmark input. The source's zero-target shortcuts and negative-value examples are outside this contract.
- The largest possible sum is 256,000,000, safely within signed 64-bit arithmetic.

## Workload

[`workload.json`](workload.json) includes the pinned example, a one-element match, multi-element matches, empty and no-match cases, and malformed or out-of-domain inputs.

## Reviewed source

- [Python `minimum_size_subarray_sum.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/minimum_size_subarray_sum.py) — expands the right edge, records the current minimum while the sum reaches the target, then subtracts values from the left edge.

This is a minimum-length contiguous-range problem. It differs from fixed-window maximum-sum routines, exact-sum range counting, and subset-sum algorithms that select noncontiguous elements.

## Implementations

The nine ports use the shared `i64_array_scalar` ABI. Their source files are in the `m` folder for each language. The source-backed oracle is implemented in `benchmarks/run_i64_array_scalar.py`.

The runner checks each workload result with the same positive-value sliding-window recurrence and malformed-input bounds.
