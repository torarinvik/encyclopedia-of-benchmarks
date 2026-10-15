# Strict Wiggle Sort

This benchmark ports the strict variant in the pinned [TheAlgorithms/Java WiggleSort](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/WiggleSort.java). It selects a median, then applies a virtual-index Dutch-flag partition so high values occupy peaks and low values occupy valleys.

## Contract

- Input has 0 through 4,096 signed 64-bit values, each in the signed 32-bit range.
- For arrays of length greater than one, output satisfies a[0] < a[1] > a[2] < a[3] ... .
- Return the transformed array as signed 32-bit little-endian bytes and its element count.
- Invalid values or an input with no strict arrangement return -1; insufficient output capacity returns -2.
- Empty input returns empty output. The pinned Java class delegates to QuickSelect, which rejects an empty list.
- The algorithm checks median multiplicity before partitioning. For odd lengths, when the median occurs ceil(n/2) times it must also be the minimum. The source throws for inputs that fail these checks; the ABI maps that case to -1.
- Ports use an upper-midpoint Hoare QuickSelect with a progress-safe interval update, followed by the source's virtual-index Dutch-flag partition. Selection takes expected O(n), worst-case O(n²); partitioning and output serialization take O(n). The ABI uses O(n) fixed temporary storage.

The Java source uses a shared median-of-medians QuickSelect helper. The benchmark shares one deterministic QuickSelect partition rule across its nine ports so exact byte outputs match between languages; the strict feasibility checks and virtual-index partition preserve the source algorithm's defining behavior.

## Workload and build

[workload.json](workload.json) covers empty and singleton arrays, feasible pairs and duplicates, signed 32-bit edges, unsortable inputs, and invalid values. The byte-output runner computes the exact arrangement using the shared pivot and virtual-index rules.

All nine implementations use the i64_array_bytes_output ABI family.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/w/wiggle_sort_strict.c](../../../c/w/wiggle_sort_strict.c) |
| C3 | [c3/w/wiggle_sort_strict.c3](../../../c3/w/wiggle_sort_strict.c3) |
| C++ | [cpp/w/wiggle_sort_strict.cpp](../../../cpp/w/wiggle_sort_strict.cpp) |
| Elisa | [elisa/w/wiggle_sort_strict.elisa](../../../elisa/w/wiggle_sort_strict.elisa) |
| Nim | [nim/w/wiggle_sort_strict.nim](../../../nim/w/wiggle_sort_strict.nim) |
| Odin | [odin/w/wiggle_sort_strict.odin](../../../odin/w/wiggle_sort_strict.odin) |
| Rust | [rust/w/wiggle_sort_strict.rs](../../../rust/w/wiggle_sort_strict.rs) |
| V | [v/w/wiggle_sort_strict.v](../../../v/w/wiggle_sort_strict.v) |
| Zig | [zig/w/wiggle_sort_strict.zig](../../../zig/w/wiggle_sort_strict.zig) |
