# Two pointers: sorted-array pair existence

This package ports the pinned Java `TwoPointers.isPairedSum` algorithm. It checks whether a sorted array contains two distinct positions whose values sum to the target, using a left/right two-pointer scan.

## Contract

- Input is the signed-i64 vector `[target, n, value_0, ..., value_(n-1)]` with exact length `n+2`. `n` is in `0..256`, target is in `[-2,000,000,2,000,000]`, and values are in `[-1,000,000,1,000,000]`.
- Values must be sorted in nondecreasing order. Duplicate values are valid, and a pair always uses two distinct indices. Empty and singleton arrays are valid and return 0.
- The implementation scans from both ends: a sum below target advances the left index; a sum above target retreats the right index; a matching sum returns 1. Exhausting the scan returns 0.
- Invalid length, node count, target/value range, or ordering returns -1. The bounds keep pair sums within signed i64 and prevent overflow in the source's signed 32-bit sum.

The independent oracle is [`benchmarks/two_pointers_pair_exists_oracle.py`](../../two_pointers_pair_exists_oracle.py). Workload cases cover positive and negative matches, duplicates, empty/singleton lists, maximum length, and malformed inputs.

Pinned source: [TheAlgorithms/Java `TwoPointers.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/others/TwoPointers.java), commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

Build and record with the `i64_array_scalar` ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm two_pointers_pair_exists --language c
python3 benchmarks/run_i64_array_scalar.py --algorithm two_pointers_pair_exists
```

| Language | Port |
| --- | --- |
| C | [`c/t/two_pointers_pair_exists.c`](../../../c/t/two_pointers_pair_exists.c) |
| C3 | [`c3/t/two_pointers_pair_exists.c3`](../../../c3/t/two_pointers_pair_exists.c3) |
| C++ | [`cpp/t/two_pointers_pair_exists.cpp`](../../../cpp/t/two_pointers_pair_exists.cpp) |
| Elisa | [`elisa/t/two_pointers_pair_exists.elisa`](../../../elisa/t/two_pointers_pair_exists.elisa) |
| Nim | [`nim/t/two_pointers_pair_exists.nim`](../../../nim/t/two_pointers_pair_exists.nim) |
| Odin | [`odin/t/two_pointers_pair_exists.odin`](../../../odin/t/two_pointers_pair_exists.odin) |
| Rust | [`rust/t/two_pointers_pair_exists.rs`](../../../rust/t/two_pointers_pair_exists.rs) |
| V | [`v/t/two_pointers_pair_exists.v`](../../../v/t/two_pointers_pair_exists.v) |
| Zig | [`zig/t/two_pointers_pair_exists.zig`](../../../zig/t/two_pointers_pair_exists.zig) |
