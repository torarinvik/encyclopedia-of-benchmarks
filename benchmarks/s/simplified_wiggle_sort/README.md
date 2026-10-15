# Simplified Wiggle Sort

This benchmark ports the pinned [TheAlgorithms/JavaScript implementation](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Sorts/SimplifiedWiggleSort.js). It selects the middle order statistic with QuickSelect, then places values greater than the median at descending odd positions and the remaining values at ascending even positions.

## Contract

- Input has 0 through 4,096 signed 64-bit values, each in the signed 32-bit range.
- Return the transformed array as signed 32-bit little-endian bytes and its element count.
- Output satisfies a[0] <= a[1] >= a[2] <= a[3] ...; equal neighbors are allowed.
- Invalid lengths or values return -1; insufficient output capacity returns -2.
- Empty input returns empty output. The pinned JavaScript function delegates to a QuickSelect helper that rejects this input.
- Selection uses an in-place Hoare partition with the upper midpoint element as pivot. It runs in expected O(n) time and worst-case O(n²); the output placement and serialization take O(n). The ABI copies input and holds the output in a fixed O(n) buffer.

The pinned [QuickSelect helper](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Search/QuickSelectSearch.js) can leave its search interval unchanged when the requested rank is at the upper boundary (for example, a two-element ascending array). The ports use a progress-safe partition while preserving the median-selection and alternating-placement approach. This makes the benchmark terminate on the documented domain.

This contract differs from [wiggle_sort](../../w/wiggle_sort/README.md), which makes local adjacent swaps in one pass and can return a different permutation.

## Workload and build

[workload.json](workload.json) covers empty and singleton arrays, two-element boundaries, duplicates, odd and even lengths, signed 32-bit edges, and invalid values. The byte-output runner computes the exact output using the same selection and placement rules.

All nine implementations use the i64_array_bytes_output ABI family.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/s/simplified_wiggle_sort.c](../../../c/s/simplified_wiggle_sort.c) |
| C3 | [c3/s/simplified_wiggle_sort.c3](../../../c3/s/simplified_wiggle_sort.c3) |
| C++ | [cpp/s/simplified_wiggle_sort.cpp](../../../cpp/s/simplified_wiggle_sort.cpp) |
| Elisa | [elisa/s/simplified_wiggle_sort.elisa](../../../elisa/s/simplified_wiggle_sort.elisa) |
| Nim | [nim/s/simplified_wiggle_sort.nim](../../../nim/s/simplified_wiggle_sort.nim) |
| Odin | [odin/s/simplified_wiggle_sort.odin](../../../odin/s/simplified_wiggle_sort.odin) |
| Rust | [rust/s/simplified_wiggle_sort.rs](../../../rust/s/simplified_wiggle_sort.rs) |
| V | [v/s/simplified_wiggle_sort.v](../../../v/s/simplified_wiggle_sort.v) |
| Zig | [zig/s/simplified_wiggle_sort.zig](../../../zig/s/simplified_wiggle_sort.zig) |
