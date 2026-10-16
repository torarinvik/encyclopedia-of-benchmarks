# Two pointers: complementary pair count

This package ports the pinned PHP `twoPointers` function. It sorts a local copy of the input values, then scans from both ends and counts complementary pairs.

## Contract

- Input is the signed-i64 vector `[target, n, value_0, ..., value_(n-1)]` with exact length `n+2`. The item count is `0..256`, the target is in `[-2,000,000, 2,000,000]`, and each value is in `[-1,000,000, 1,000,000]`.
- Values may arrive in any order, but they must be pairwise distinct. Empty and singleton arrays are valid and return zero.
- The ports sort a private copy in ascending order. A sum below the target advances the left pointer; a sum above it retreats the right pointer. On equality, the count increases and only the left pointer advances, matching the source. Distinct values ensure the fixed right value cannot match a later left value as well.
- The result is the number of disjoint complementary value pairs, from 0 through 128. Invalid length, count, target/value range, or duplicate values returns `-1`.

The independent oracle in [`benchmarks/two_pointers_pair_count_oracle.py`](../../two_pointers_pair_count_oracle.py) directly counts matching index pairs. The workload includes the upstream example, unsorted inputs, empty/singleton arrays, duplicate rejection, malformed lengths, and the maximum 256-value case.

Pinned source: [TheAlgorithms/PHP `TwoPointers.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Searches/TwoPointers.php), commit `b8a54469cc36332ef2934101b58d71075ef1d78e`.

Build and record with the `i64_array_scalar` ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm two_pointers_pair_count --language c
python3 benchmarks/run_i64_array_scalar.py --algorithm two_pointers_pair_count
```

| Language | Port |
| --- | --- |
| C | [`c/t/two_pointers_pair_count.c`](../../../c/t/two_pointers_pair_count.c) |
| C3 | [`c3/t/two_pointers_pair_count.c3`](../../../c3/t/two_pointers_pair_count.c3) |
| C++ | [`cpp/t/two_pointers_pair_count.cpp`](../../../cpp/t/two_pointers_pair_count.cpp) |
| Elisa | [`elisa/t/two_pointers_pair_count.elisa`](../../../elisa/t/two_pointers_pair_count.elisa) |
| Nim | [`nim/t/two_pointers_pair_count.nim`](../../../nim/t/two_pointers_pair_count.nim) |
| Odin | [`odin/t/two_pointers_pair_count.odin`](../../../odin/t/two_pointers_pair_count.odin) |
| Rust | [`rust/t/two_pointers_pair_count.rs`](../../../rust/t/two_pointers_pair_count.rs) |
| V | [`v/t/two_pointers_pair_count.v`](../../../v/t/two_pointers_pair_count.v) |
| Zig | [`zig/t/two_pointers_pair_count.zig`](../../../zig/t/two_pointers_pair_count.zig) |

