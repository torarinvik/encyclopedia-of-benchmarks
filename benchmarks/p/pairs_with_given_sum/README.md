# Pairs with a given sum

Count every pair of distinct array positions whose values add to a requested sum. This follows the pinned Python implementation's enumeration of all two-element combinations, including multiplicity when values repeat. It is distinct from `two_sum`, which returns one pair of indices, and `array_pair_sum`, which sorts and pairs adjacent values.

## Contract

- Input is a signed 64-bit array packed as `[target, value_0, value_1, ...]`. Target and values must fit signed 32-bit integers; at most 256 values are accepted.
- Count all pairs `(i, j)` where `i < j` and `value_i + value_j == target`. Duplicate values at different positions count as separate pairs. With only the target and no values, return 0.
- Return `-2` for a missing target, an input longer than 257 packed values, or any target/value outside signed 32-bit range.
- The ports use a direct nested scan, matching the source's O(n^2) pair enumeration. The maximum result is 32,640.

Pinned source: [TheAlgorithms/Python `pairs_with_given_sum.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/arrays/pairs_with_given_sum.py).

[`workload.json`](workload.json) covers the upstream examples, empty and singleton arrays, repeated values, negative and boundary values, no matches, malformed inputs, and the maximum array size. The independent oracle is [`benchmarks/pairs_with_given_sum_oracle.py`](../../pairs_with_given_sum_oracle.py).

Build and verify with the shared scalar-array tools:

    python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm pairs_with_given_sum --language rust --with-checker
    python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/p/pairs_with_given_sum/rust/build.json
    python3 benchmarks/verify_i64_array_scalar.py --algorithms pairs_with_given_sum --languages rust

| Language | Source |
| --- | --- |
| C | [`c/p/pairs_with_given_sum.c`](../../../c/p/pairs_with_given_sum.c) |
| C3 | [`c3/p/pairs_with_given_sum.c3`](../../../c3/p/pairs_with_given_sum.c3) |
| C++ | [`cpp/p/pairs_with_given_sum.cpp`](../../../cpp/p/pairs_with_given_sum.cpp) |
| Elisa | [`elisa/p/pairs_with_given_sum.elisa`](../../../elisa/p/pairs_with_given_sum.elisa) |
| Nim | [`nim/p/pairs_with_given_sum.nim`](../../../nim/p/pairs_with_given_sum.nim) |
| Odin | [`odin/p/pairs_with_given_sum.odin`](../../../odin/p/pairs_with_given_sum.odin) |
| Rust | [`rust/p/pairs_with_given_sum.rs`](../../../rust/p/pairs_with_given_sum.rs) |
| V | [`v/p/pairs_with_given_sum.v`](../../../v/p/pairs_with_given_sum.v) |
| Zig | [`zig/p/pairs_with_given_sum.zig`](../../../zig/p/pairs_with_given_sum.zig) |
