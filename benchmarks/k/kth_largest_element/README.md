# Kth Largest Element by Quickselect

The pinned Python source partitions in descending order with the last element as pivot, then narrows the search to the side containing zero-based rank `k - 1`. The nine ports preserve that Lomuto quickselect and work on a private copy of the input.

## Contract

- Input is `[k, value_0, value_1, ...]`.
- There are 1 through 512 signed 32-bit values, and `k` is from 1 through the number of values.
- Duplicate values count as separate positions. Inputs are read only; invalid inputs return `-1`.
- The result is the value at descending rank `k - 1`. Average time is O(n); worst-case time is O(n²) with the last-element pivot. The local copy uses O(n) space.

## Workload and verification

[`workload.json`](workload.json) covers first, middle, and last ranks, duplicates, negative values, signed 32-bit boundaries, sorted orders, and a 512-element input. [`benchmarks/verify_kth_largest.py`](../../verify_kth_largest.py) checks both the quickselect and full-sort benchmarks against an independent sorting oracle.

## Upstream source

- [TheAlgorithms/Python `kth_largest_element.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/arrays/kth_largest_element.py)
