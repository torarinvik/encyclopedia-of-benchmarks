# Maximum Product Subarray

Return the largest product among all contiguous subarrays, using the pinned Python source's maximum/minimum tracking recurrence.

## Contract

- The `i64_array_scalar` ABI accepts a signed 64-bit integer array of length 0 through 9.
- Each value must be in `[-10, 10]`. Empty input returns 0, matching the Python source.
- For nonempty input, initialize the current maximum, current minimum, and global maximum from the first value. For each later value, swap the current maximum and minimum if it is negative; then update the current maximum with `max(value, current_max * value)`, the current minimum with `min(value, current_min * value)`, and the global maximum with the current maximum.
- Invalid lengths or values return `INT64_MIN`. The bound keeps every intermediate product within signed 32-bit range, so the result is exact in all ports.

## Source semantics and related candidates

The canonical pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/max_product_subarray.py) returns 0 for an empty sequence and tracks both maximum and minimum products because a negative value can reverse their roles. This differs from the sum-based `maximum_subarray` benchmark.

The Java and Ruby sources cataloged under `maximum_product_subarray` use the same recurrence on nonempty arrays. The Java implementation returns an `int`, so the shared small-value bound avoids its narrowing edge. The Ruby implementation initializes its answer to -11 and therefore returns -11 for empty input; this package follows Python's empty-input result 0.

## Workload

[`workload.json`](workload.json) covers the pinned examples, zeros, negative singleton values, the empty case, maximum product, bounds, and invalid values.
