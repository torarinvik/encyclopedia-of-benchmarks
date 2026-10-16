# External Merge Sorter

This benchmark maps the pinned C# `ExternalMergeSorter<T>` to a bounded in-memory workload. Its source alternates sequential input and temporary storage on bottom-up merge passes, beginning with run width 1 and doubling the width after each pass. The benchmark models those sequential stores with two fixed buffers; it does not time disk access or a storage adapter. The source chooses the right run when compared values are equal. For this scalar integer contract, the order of equal values is not observable.

## Contract

The `i64_array_bytes_output` input is a sequence of 0 to 4096 signed 64-bit integers. A null input pointer with nonzero length or a length above 4096 returns `-1`. The output is the values sorted in ascending signed order and encoded as little-endian signed 64-bit integers. The return value is the number of bytes written. A null output pointer or insufficient output capacity returns `-2`; empty input is valid and returns zero bytes.

The largest output is 32,768 bytes. The workload covers empty and singleton inputs, duplicate values, signed 64-bit boundaries, a 4096-value deterministic modular-affine input, and insufficient output capacity. See [`workload.json`](workload.json).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/e/external_merge_sorter.c`](../../../c/e/external_merge_sorter.c) |
| C3 | [`c3/e/external_merge_sorter.c3`](../../../c3/e/external_merge_sorter.c3) |
| C++ | [`cpp/e/external_merge_sorter.cpp`](../../../cpp/e/external_merge_sorter.cpp) |
| Elisa | [`elisa/e/external_merge_sorter.elisa`](../../../elisa/e/external_merge_sorter.elisa) |
| Nim | [`nim/e/external_merge_sorter.nim`](../../../nim/e/external_merge_sorter.nim) |
| Odin | [`odin/e/external_merge_sorter.odin`](../../../odin/e/external_merge_sorter.odin) |
| Rust | [`rust/e/external_merge_sorter.rs`](../../../rust/e/external_merge_sorter.rs) |
| V | [`v/e/external_merge_sorter.v`](../../../v/e/external_merge_sorter.v) |
| Zig | [`zig/e/external_merge_sorter.zig`](../../../zig/e/external_merge_sorter.zig) |

## TheAlgorithms source

The candidate is the pinned [C# `ExternalMergeSorter.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sorters/External/ExternalMergeSorter.cs).
