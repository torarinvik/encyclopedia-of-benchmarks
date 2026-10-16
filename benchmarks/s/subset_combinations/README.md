# Subset Combinations

Generate every choice of `k` positions from an input list. Positions are distinct, so repeated element values still produce distinct combinations.

## Contract

- The input is `[k, item0, ...]`, with at most 12 items.
- `k` must be nonnegative. If `k` is greater than the item count, return zero combinations; `k = 0` returns the single empty combination.
- Return the number of combinations and write each selected-position mask as two little-endian bytes. Bit `i` represents input position `i`. Combinations follow lexicographic index order.
- Invalid length or negative `k` returns `-1`; insufficient output capacity returns `-2` without writing output.

## Reviewed TheAlgorithms sources

The pinned [Python `subset_generation.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/subset_generation.py) builds fixed-size combinations with a dynamic-programming table and sorts numeric tuples. The [Rust `subset_generation.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/dynamic_programming/subset_generation.rs) recursively generates the same fixed-size selections. This contract identifies combinations by input position, retaining duplicate choices and a stable cross-language order.

The Rust [`all_combination_of_size_k`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/backtracking/all_combination_of_size_k.rs), JavaScript [`AllCombinationsOfSizeK`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Backtracking/AllCombinationsOfSizeK.js), TypeScript [`all_combinations_of_size_k`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/backtracking/all_combinations_of_size_k.ts), and Python [`all_combinations.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/backtracking/all_combinations.py) candidates enumerate the same fixed-size selections from a numeric range, returning nested value vectors instead of masks. With a range-valued input universe, each tuple maps directly to the same position mask. Their recursive backtracking overlaps the Rust subset-generation source; the shared benchmark normalizes the output representation and boundary behavior. The Rust candidate uses `0..n-1`; the other three use `1..n`. Their invalid-boundary behavior differs (`k > n` returns an error in Rust, and TypeScript omits the empty selection for `k = 0`), so the shared contract defines those cases explicitly.

Java's [`ArrayCombination.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/backtracking/ArrayCombination.java) also enumerates combinations recursively in lexicographic order; it maps when the input values are `0..n-1`.

## Workload and verification

[`workload.json`](workload.json) covers empty selections, full selections, duplicate values, `k` above the item count, and signed 64-bit element boundaries. [`benchmarks/verify_subset_combinations.py`](../../verify_subset_combinations.py) checks all nine ports against Python's index-combination oracle and tests insufficient output capacity.

## Implementations

All nine implementations use the shared i64-array/bytes-output ABI.
