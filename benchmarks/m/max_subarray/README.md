# Maximum subarray by divide and conquer

Return the greatest sum of any nonempty contiguous subarray using divide and conquer. Recursively solve the left and right halves, then compare those results with the best subarray that crosses the midpoint.

## Contract

- Input is an array of signed 64-bit values with length 1 through 1,024.
- Each element must be in the signed 32-bit range.
- Return the maximum sum of a nonempty contiguous subarray.
- Empty, oversized, or out-of-range inputs return -1.

All valid sums fit in signed 64-bit arithmetic. This benchmark shares its contract and workload with [maximum_subarray](../maximum_subarray/README.md), which uses Kadane's linear scan.

## Workload and verification

The workload covers empty and singleton arrays, all-negative and mixed values, signed 32-bit boundaries, the maximum length, and invalid length and element values. [`verify_maximum_subarray.py`](../../verify_maximum_subarray.py) checks both strategies against an independent brute-force oracle on exhaustive short arrays, deterministic random arrays, boundaries, and all published cases.

## Reviewed TheAlgorithms source

The Python [divide-and-conquer max_subarray](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/divide_and_conquer/max_subarray.py) returns start/end indices together with the maximum sum. This benchmark compares its sum objective and keeps the recursive divide-and-conquer strategy distinct from Kadane's scan.

## Implementations

All nine portable implementations use the shared i64-array/scalar ABI.
