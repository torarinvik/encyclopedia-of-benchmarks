# Wiggle Sort

This benchmark ports the one-pass adjacent-swap algorithm in the pinned [TheAlgorithms/Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/wiggle_sort.py), with matching implementations in [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/sorting/wiggle_sort.rs) and [R](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/sorting_algorithms/wiggle_sort.r). It scans from left to right and swaps neighboring values only when the pair violates the alternating pattern.

## Contract

- Input has 0 through 4,096 signed 64-bit values, each in the signed 32-bit range.
- Return the transformed array as signed 32-bit little-endian bytes and its element count.
- Output satisfies `a[0] <= a[1] >= a[2] <= a[3] ...`; equal neighbors are allowed.
- Invalid lengths or values return `-1`; insufficient output capacity returns `-2`.
- The scan takes O(n) time. The ABI implementations use O(n) temporary storage to copy and serialize the result.

The pinned R example uses `2:n`, which has an awkward empty-vector case in R. The shared contract defines empty input as empty output, matching Python and Rust. The pinned [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/wiggle_sort.cpp) and [C++-1](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/sorting/wiggle_sort.cpp) variants instead make even positions peaks and are represented by [`wave_sort_greedy`](../wave_sort_greedy/README.md). Java's [implementation](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/WiggleSort.java) uses a median and virtual-index Dutch-flag partition for strict wiggles, with an error on unsortable inputs; that is a separate algorithm and contract.

## Workload and build

[`workload.json`](workload.json) covers empty and singleton arrays, source examples, ascending and descending values, duplicates, signed 32-bit edges, and invalid values. The byte-output runner computes the exact expected arrangement for this one-pass algorithm.

All nine implementations use the `i64_array_bytes_output` ABI family.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/w/wiggle_sort.c`](../../../c/w/wiggle_sort.c) |
| C3 | [`c3/w/wiggle_sort.c3`](../../../c3/w/wiggle_sort.c3) |
| C++ | [`cpp/w/wiggle_sort.cpp`](../../../cpp/w/wiggle_sort.cpp) |
| Elisa | [`elisa/w/wiggle_sort.elisa`](../../../elisa/w/wiggle_sort.elisa) |
| Nim | [`nim/w/wiggle_sort.nim`](../../../nim/w/wiggle_sort.nim) |
| Odin | [`odin/w/wiggle_sort.odin`](../../../odin/w/wiggle_sort.odin) |
| Rust | [`rust/w/wiggle_sort.rs`](../../../rust/w/wiggle_sort.rs) |
| V | [`v/w/wiggle_sort.v`](../../../v/w/wiggle_sort.v) |
| Zig | [`zig/w/wiggle_sort.zig`](../../../zig/w/wiggle_sort.zig) |
