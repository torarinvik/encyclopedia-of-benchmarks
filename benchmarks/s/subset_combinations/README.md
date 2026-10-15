# Subset Combinations

Generate every choice of `k` positions from an input list. Positions are distinct, so repeated element values still produce distinct combinations.

## Contract

- The input is `[k, item0, ...]`, with at most 12 items.
- `k` must be nonnegative. If `k` is greater than the item count, return zero combinations; `k = 0` returns the single empty combination.
- Return the number of combinations and write each selected-position mask as two little-endian bytes. Bit `i` represents input position `i`. Combinations follow lexicographic index order.
- Invalid length or negative `k` returns `-1`; insufficient output capacity returns `-2` without writing output.

## Reviewed TheAlgorithms sources

The pinned [Python `subset_generation.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/subset_generation.py) builds fixed-size combinations with a dynamic-programming table and sorts numeric tuples. The [Rust `subset_generation.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/dynamic_programming/subset_generation.rs) recursively generates the same fixed-size selections. This contract identifies combinations by input position, retaining duplicate choices and a stable cross-language order.

## Workload and verification

[`workload.json`](workload.json) covers empty selections, full selections, duplicate values, `k` above the item count, and signed 64-bit element boundaries. [`benchmarks/verify_subset_combinations.py`](../../verify_subset_combinations.py) checks all nine ports against Python's index-combination oracle and tests insufficient output capacity.

## Implementations

All nine implementations use the shared i64-array/bytes-output ABI.
