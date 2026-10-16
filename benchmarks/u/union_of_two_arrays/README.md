# Union of Two Arrays

Merge two sorted integer arrays into one sorted array containing each value once. The package follows the pinned C++ implementation's two-cursor merge, including its handling of duplicate values in either input.

## Contract

- Pack the `i64_array_bytes_output` input as `[n1, array1..., n2, array2...]`. Each array length is from 0 through 64, and packed input length must equal `2+n1+n2`.
- Values must fit signed 32-bit integers. Arrays must be non-decreasing; duplicates are allowed.
- Emit the sorted unique union as little-endian signed 32-bit integers. Return the number of values written; an empty union returns 0 and zero bytes.
- Invalid packing, ordering, or value range returns `-1`. Output capacity must hold up to `4*(n1+n2)` bytes; insufficient capacity returns `-2` without writing. The maximum output workspace is 512 bytes.

## Source and workload

Both pinned C++ repositories contain the same `get_union` routine:

- [TheAlgorithms/C-Plus-Plus `union_of_two_arrays.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/operations_on_datastructures/union_of_two_arrays.cpp)
- [TheAlgorithms/C-Plus-Plus-1 `union_of_two_arrays.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/operations_on_datastructures/union_of_two_arrays.cpp)

The source assumes sorted arrays, advances both cursors for equal values, and appends only when a value differs from the last output. The workload includes empty inputs, interleaved and disjoint values, duplicates, signed 32-bit boundaries, maximum-size output, malformed inputs, and an insufficient-capacity case. [`union_of_two_arrays_oracle.py`](../../union_of_two_arrays_oracle.py) calculates the result independently using set union and sorting.

The pinned C++ repository license is [MIT](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/LICENSE).

Build with the shared byte-output ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm union_of_two_arrays --language rust
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm union_of_two_arrays
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/u/union_of_two_arrays.c`](../../../c/u/union_of_two_arrays.c) |
| C3 | [`c3/u/union_of_two_arrays.c3`](../../../c3/u/union_of_two_arrays.c3) |
| C++ | [`cpp/u/union_of_two_arrays.cpp`](../../../cpp/u/union_of_two_arrays.cpp) |
| Elisa | [`elisa/u/union_of_two_arrays.elisa`](../../../elisa/u/union_of_two_arrays.elisa) |
| Nim | [`nim/u/union_of_two_arrays.nim`](../../../nim/u/union_of_two_arrays.nim) |
| Odin | [`odin/u/union_of_two_arrays.odin`](../../../odin/u/union_of_two_arrays.odin) |
| Rust | [`rust/u/union_of_two_arrays.rs`](../../../rust/u/union_of_two_arrays.rs) |
| V | [`v/u/union_of_two_arrays.v`](../../../v/u/union_of_two_arrays.v) |
| Zig | [`zig/u/union_of_two_arrays.zig`](../../../zig/u/union_of_two_arrays.zig) |
