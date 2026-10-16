# Intersection of Two Arrays

Intersect two sorted integer arrays and return each common value once in ascending order. The package follows the pinned C++ two-cursor routine, including its behavior on duplicate values.

## Contract

- Pack the `i64_array_bytes_output` input as `[n1, array1..., n2, array2...]`. Each array length is from 0 through 64, and the packed input length is exactly `2+n1+n2`.
- Values must fit signed 32-bit integers. Arrays must be non-decreasing; duplicates are allowed.
- Emit the unique common values in ascending order as little-endian signed 32-bit integers. Return the number of values written; an empty result returns 0 bytes.
- Invalid packing, ordering, or value range returns `-1`. Output capacity must hold up to `4*min(n1,n2)` bytes; insufficient capacity returns `-2`. The maximum output workspace is 256 bytes.

The two-array source is distinct from [`sorted_arrays_intersection`](../../s/sorted_arrays_intersection/README.md), which intersects three strictly increasing arrays. It also differs from [`arrays_intersection`](../../a/arrays_intersection/README.md), which counts occurrences across three unsorted arrays.

## Source and workload

The C++ and C++-1 repositories contain the same pinned `get_intersection` routine:

- [TheAlgorithms/C-Plus-Plus `intersection_of_two_arrays.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/operations_on_datastructures/intersection_of_two_arrays.cpp)
- [TheAlgorithms/C-Plus-Plus-1 `intersection_of_two_arrays.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/operations_on_datastructures/intersection_of_two_arrays.cpp)

[`workload.json`](workload.json) covers empty and non-empty inputs, duplicate values, signed 32-bit boundaries, full-capacity output, invalid ordering/packing, and the capacity sentinel. [`intersection_of_two_arrays_oracle.py`](../../intersection_of_two_arrays_oracle.py) computes the set intersection independently.

Build with the shared byte-output ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm intersection_of_two_arrays --language rust
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm intersection_of_two_arrays
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/i/intersection_of_two_arrays.c`](../../../c/i/intersection_of_two_arrays.c) |
| C3 | [`c3/i/intersection_of_two_arrays.c3`](../../../c3/i/intersection_of_two_arrays.c3) |
| C++ | [`cpp/i/intersection_of_two_arrays.cpp`](../../../cpp/i/intersection_of_two_arrays.cpp) |
| Elisa | [`elisa/i/intersection_of_two_arrays.elisa`](../../../elisa/i/intersection_of_two_arrays.elisa) |
| Nim | [`nim/i/intersection_of_two_arrays.nim`](../../../nim/i/intersection_of_two_arrays.nim) |
| Odin | [`odin/i/intersection_of_two_arrays.odin`](../../../odin/i/intersection_of_two_arrays.odin) |
| Rust | [`rust/i/intersection_of_two_arrays.rs`](../../../rust/i/intersection_of_two_arrays.rs) |
| V | [`v/i/intersection_of_two_arrays.v`](../../../v/i/intersection_of_two_arrays.v) |
| Zig | [`zig/i/intersection_of_two_arrays.zig`](../../../zig/i/intersection_of_two_arrays.zig) |
