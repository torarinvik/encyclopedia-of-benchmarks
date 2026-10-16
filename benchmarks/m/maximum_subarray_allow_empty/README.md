# Maximum subarray allowing the empty subarray

Return the greatest sum of a contiguous subarray while allowing the empty subarray, whose sum is zero. This follows the sum component of the pinned Haskell `maxSubArray` result.

## Contract

- Input is a signed 64-bit integer array with length 0 through 1,024; every value must be a signed 32-bit integer.
- Return the maximum subarray sum allowing the empty choice. Empty input and all-negative input therefore return `0`.
- Oversized or out-of-range input returns `-1`. Valid results are nonnegative, so the invalid sentinel is distinct.
- The source recurrence starts with `maxSoFar = 0` and `maxEndingHere = 0`, then updates the running sum for each input value. The benchmark projects the sum from the source's `(sum, start, end)` tuple.

This empty-allowed contract differs from [`maximum_subarray`](../maximum_subarray/README.md), which requires a nonempty subarray and returns a negative maximum for all-negative input.

## Workload and source

[`workload.json`](workload.json) covers empty input, all-negative and mixed arrays, zero-valued maxima, signed 32-bit boundaries, maximum length, and malformed inputs. The independent oracle is [`maximum_subarray_allow_empty_oracle.py`](../../maximum_subarray_allow_empty_oracle.py).

- [TheAlgorithms/Haskell `Maths/KadaneAlgorithm.hs`](https://github.com/TheAlgorithms/Haskell/blob/9dcabef99fb8995a760ff25a9e0d659114c0b9d3/src/Maths/KadaneAlgorithm.hs)

## Build and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm maximum_subarray_allow_empty --language rust
python3 benchmarks/verify_i64_array_scalar.py --algorithms maximum_subarray_allow_empty
```

## Implementations

| Language | Port |
| --- | --- |
| C | [`c/m/maximum_subarray_allow_empty.c`](../../../c/m/maximum_subarray_allow_empty.c) |
| C3 | [`c3/m/maximum_subarray_allow_empty.c3`](../../../c3/m/maximum_subarray_allow_empty.c3) |
| C++ | [`cpp/m/maximum_subarray_allow_empty.cpp`](../../../cpp/m/maximum_subarray_allow_empty.cpp) |
| Elisa | [`elisa/m/maximum_subarray_allow_empty.elisa`](../../../elisa/m/maximum_subarray_allow_empty.elisa) |
| Nim | [`nim/m/maximum_subarray_allow_empty.nim`](../../../nim/m/maximum_subarray_allow_empty.nim) |
| Odin | [`odin/m/maximum_subarray_allow_empty.odin`](../../../odin/m/maximum_subarray_allow_empty.odin) |
| Rust | [`rust/m/maximum_subarray_allow_empty.rs`](../../../rust/m/maximum_subarray_allow_empty.rs) |
| V | [`v/m/maximum_subarray_allow_empty.v`](../../../v/m/maximum_subarray_allow_empty.v) |
| Zig | [`zig/m/maximum_subarray_allow_empty.zig`](../../../zig/m/maximum_subarray_allow_empty.zig) |
