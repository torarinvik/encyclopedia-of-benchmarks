# Maximum circular subarray

Return the greatest sum of a nonempty contiguous segment of a circular array. The implementation follows the pinned C++ Kadane variant: it tracks the maximum and minimum contiguous sums, then compares the ordinary maximum with the total minus the minimum. If the minimum spans the entire array, it returns the ordinary maximum so the chosen segment stays nonempty.

## Contract

- Input is an array of signed 64-bit values with length 1 through 64.
- Each value is in `[-1000000, 1000000]`. This bound keeps every accumulated sum within the signed 32-bit range used by the source implementation.
- Return the maximum sum of a nonempty contiguous segment, allowing the segment to wrap from the end of the array to its beginning.
- Null, empty, overlength, or out-of-range inputs return `INT64_MIN`, which is outside the valid result range.

## Workload and oracle

[`workload.json`](workload.json) covers singleton, all-positive, all-negative, wraparound, source examples, zero, maximum-length, and malformed inputs. The independent oracle is [`maximum_circular_subarray_oracle.py`](../../maximum_circular_subarray_oracle.py).

## Reviewed source implementations

- [TheAlgorithms/C-Plus-Plus `maximum_circular_subarray.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/dynamic_programming/maximum_circular_subarray.cpp)
- [TheAlgorithms/C-Plus-Plus-1 `maximum_circular_subarray.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/dynamic_programming/maximum_circular_subarray.cpp)

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm maximum_circular_subarray --language rust
python3 benchmarks/run_i64_array_scalar.py --algorithm maximum_circular_subarray
python3 benchmarks/verify_i64_array_scalar.py --algorithm maximum_circular_subarray
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/m/maximum_circular_subarray.c`](../../../c/m/maximum_circular_subarray.c) |
| C3 | [`c3/m/maximum_circular_subarray.c3`](../../../c3/m/maximum_circular_subarray.c3) |
| C++ | [`cpp/m/maximum_circular_subarray.cpp`](../../../cpp/m/maximum_circular_subarray.cpp) |
| Elisa | [`elisa/m/maximum_circular_subarray.elisa`](../../../elisa/m/maximum_circular_subarray.elisa) |
| Nim | [`nim/m/maximum_circular_subarray.nim`](../../../nim/m/maximum_circular_subarray.nim) |
| Odin | [`odin/m/maximum_circular_subarray.odin`](../../../odin/m/maximum_circular_subarray.odin) |
| Rust | [`rust/m/maximum_circular_subarray.rs`](../../../rust/m/maximum_circular_subarray.rs) |
| V | [`v/m/maximum_circular_subarray.v`](../../../v/m/maximum_circular_subarray.v) |
| Zig | [`zig/m/maximum_circular_subarray.zig`](../../../zig/m/maximum_circular_subarray.zig) |
