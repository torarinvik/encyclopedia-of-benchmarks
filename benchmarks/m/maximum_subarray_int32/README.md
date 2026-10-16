# Maximum subarray with bounded int32 sums

Return the greatest sum of any nonempty contiguous subarray using Kadane's linear scan. This contract covers the corrected C++ and Rust implementations whose source functions return a signed 32-bit result.

## Contract

- Input is a signed 64-bit integer array with length 1 through 1,024; every value must be in `[-1,000,000, 1,000,000]`.
- Return the maximum sum of a nonempty contiguous subarray. The bound keeps every possible subarray sum within signed 32-bit range `[-1,024,000,000, 1,024,000,000]`.
- Empty, oversized, or out-of-range input returns `-1`. Since `-1` can also be a valid maximum, callers distinguish it using the input length and domain.
- The algorithm keeps the maximum sum ending at the current position and the maximum seen so far, using O(n) time and O(1) extra space.

This bounded result contract is separate from [`maximum_subarray`](../maximum_subarray/README.md), whose wider input range includes sums that do not fit the source C++ `int` and Rust `i32` return types.

## Workload and source

[`workload.json`](workload.json) covers the pinned examples, negative and mixed arrays, the signed result bounds, the maximum length, and malformed inputs. The independent oracle is [`maximum_subarray_int32_oracle.py`](../../maximum_subarray_int32_oracle.py).

- [TheAlgorithms/C-Plus-Plus-1 `dynamic_programming/kadane.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/dynamic_programming/kadane.cpp)
- [TheAlgorithms/C-Plus-Plus `others/kadanes3.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/others/kadanes3.cpp)
- [TheAlgorithms/C-Plus-Plus-1 `others/kadanes3.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/others/kadanes3.cpp)
- [TheAlgorithms/Rust `general/kadane_algorithm.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/general/kadane_algorithm.rs)

## Build and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm maximum_subarray_int32 --language rust
python3 benchmarks/verify_i64_array_scalar.py --algorithms maximum_subarray_int32
```

## Implementations

| Language | Port |
| --- | --- |
| C | [`c/m/maximum_subarray_int32.c`](../../../c/m/maximum_subarray_int32.c) |
| C3 | [`c3/m/maximum_subarray_int32.c3`](../../../c3/m/maximum_subarray_int32.c3) |
| C++ | [`cpp/m/maximum_subarray_int32.cpp`](../../../cpp/m/maximum_subarray_int32.cpp) |
| Elisa | [`elisa/m/maximum_subarray_int32.elisa`](../../../elisa/m/maximum_subarray_int32.elisa) |
| Nim | [`nim/m/maximum_subarray_int32.nim`](../../../nim/m/maximum_subarray_int32.nim) |
| Odin | [`odin/m/maximum_subarray_int32.odin`](../../../odin/m/maximum_subarray_int32.odin) |
| Rust | [`rust/m/maximum_subarray_int32.rs`](../../../rust/m/maximum_subarray_int32.rs) |
| V | [`v/m/maximum_subarray_int32.v`](../../../v/m/maximum_subarray_int32.v) |
| Zig | [`zig/m/maximum_subarray_int32.zig`](../../../zig/m/maximum_subarray_int32.zig) |
