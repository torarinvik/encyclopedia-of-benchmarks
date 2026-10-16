# Library sort

Sort an in-place signed integer array in ascending order with Library Sort, also called gapped insertion sort. The implementation keeps values in a sparse array, inserts each batch into gaps, and redistributes the occupied values evenly between batches.

## Contract

- The `sort_call` ABI receives a mutable array and its length. Length is from 0 through 256; empty and one-element arrays are unchanged.
- Input values are signed 32-bit integers transported through the shared signed 64-bit ABI.
- The result is the input multiset in nondecreasing order. Duplicate values are retained. Stability is not part of this integer-only contract.
- The bounded ports follow the pinned Java implementation: a `2 * length` sparse array, insertion batches of 1, 2, 4, ... values, and even redistribution of occupied slots between batches.

## Workload

[`workload.json`](workload.json) uses deterministic modular-affine inputs at lengths 0, 16, 64, 128, and 256. The shared sort runner restores the input before each sample and compares the complete result against an ascending reference. [`library_sort_oracle.py`](../../library_sort_oracle.py) provides an independent bounded sorted-output oracle and the runner's FNV-1a checksum calculation.

## Upstream review

The pinned Java `LibrarySort.sort` implementation is the source basis. It uses a sparse array twice the input length, inserts batches that double in size, and rebalances the occupied values evenly after each batch. It inserts after equal values; the contract compares integer values only, so duplicate order is unobservable.

The two pinned C++ files are excluded from this benchmark. They read an uninitialized `bool` occupancy array, copy an uninitialized library slot during rebalancing, and dereference the first input for length zero. The candidate is distinct from ordinary insertion sort and binary insertion sort because its defining operation is insertion into distributed gaps with periodic rebalancing.

Pinned Java source: [LibrarySort.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/LibrarySort.java).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/l/library_sort.c`](../../../c/l/library_sort.c) |
| C3 | [`c3/l/library_sort.c3`](../../../c3/l/library_sort.c3) |
| C++ | [`cpp/l/library_sort.cpp`](../../../cpp/l/library_sort.cpp) |
| Elisa | [`elisa/l/library_sort.elisa`](../../../elisa/l/library_sort.elisa) |
| Nim | [`nim/l/library_sort.nim`](../../../nim/l/library_sort.nim) |
| Odin | [`odin/l/library_sort.odin`](../../../odin/l/library_sort.odin) |
| Rust | [`rust/l/library_sort.rs`](../../../rust/l/library_sort.rs) |
| V | [`v/l/library_sort.v`](../../../v/l/library_sort.v) |
| Zig | [`zig/l/library_sort.zig`](../../../zig/l/library_sort.zig) |
