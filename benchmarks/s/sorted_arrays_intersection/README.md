# Sorted arrays intersection

Return the values shared by three strictly increasing integer arrays, in ascending order. This follows the pinned Ruby [`sorted_arrays_intersection`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/arrays/sorted_arrays_intersection.rb) routine, which advances three cursors until one array is exhausted.

## Contract

- Pack the input as `[n1, array1..., n2, array2..., n3, array3...]`. Each length is from 0 through 64, and the packed input has exactly `3 + n1 + n2 + n3` signed 64-bit values.
- Each array must be strictly increasing. Values must fit the signed 32-bit range.
- The output contains each common value once, in ascending order, as little-endian signed 32-bit integers. The return value is the number of values written. Empty intersections return 0 and write zero bytes.
- Malformed input returns `-1`; insufficient output capacity returns `-2`. The maximum output is 64 values (256 bytes).
- The three arrays have no duplicates, so the intersection is unique. This benchmark is distinct from the hash-based three-array [`arrays_intersection`](../../a/arrays_intersection/README.md), which counts occurrences and preserves first-seen order.

The algorithm uses constant auxiliary state and advances a cursor in the source arrays, taking O(n1 + n2 + n3) time in the worst case.

[`workload.json`](workload.json) includes the pinned examples, empty arrays, negative and signed-boundary values, cursor advancement ties, and malformed packed inputs.

Verify all available implementations with `python3 benchmarks/verify_i64_array_bytes_output.py --algorithm sorted_arrays_intersection`.

| Language | Source |
| --- | --- |
| C | [`c/s/sorted_arrays_intersection.c`](../../../c/s/sorted_arrays_intersection.c) |
| C3 | [`c3/s/sorted_arrays_intersection.c3`](../../../c3/s/sorted_arrays_intersection.c3) |
| C++ | [`cpp/s/sorted_arrays_intersection.cpp`](../../../cpp/s/sorted_arrays_intersection.cpp) |
| Elisa | [`elisa/s/sorted_arrays_intersection.elisa`](../../../elisa/s/sorted_arrays_intersection.elisa) |
| Nim | [`nim/s/sorted_arrays_intersection.nim`](../../../nim/s/sorted_arrays_intersection.nim) |
| Odin | [`odin/s/sorted_arrays_intersection.odin`](../../../odin/s/sorted_arrays_intersection.odin) |
| Rust | [`rust/s/sorted_arrays_intersection.rs`](../../../rust/s/sorted_arrays_intersection.rs) |
| V | [`v/s/sorted_arrays_intersection.v`](../../../v/s/sorted_arrays_intersection.v) |
| Zig | [`zig/s/sorted_arrays_intersection.zig`](../../../zig/s/sorted_arrays_intersection.zig) |

## Workload

The `i64_array_bytes_output` ABI accepts the packed signed 64-bit input, writes the result values to a caller-provided byte buffer, and returns the result count. Input values are checked against the signed 32-bit domain.
