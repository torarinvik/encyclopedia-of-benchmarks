# BST from sorted array

Build the balanced binary search tree produced by recursively selecting the lower midpoint of each sorted slice.

## Contract

The `i64_array_scalar` input is a strictly increasing array of signed 32-bit values, with at most 15 elements. Empty input is valid and produces an empty tree; malformed input returns `-1`.

The signed 64-bit result is a bitset of occupied positions in the tree's implicit heap layout: root index 0, left child `2i+1`, and right child `2i+2`. Since the input is sorted and unique, the shape fully identifies which input values occupy each node. This compact output makes implementations comparable without serializing pointers or allocator details.

## Source

- Java [`BSTFromSortedArray.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/BSTFromSortedArray.java)

The pinned source returns null for null or empty input and uses `start + (end - start) / 2`, which selects the lower midpoint for even-length slices.

## Workload and verification

[`workload.json`](workload.json) covers empty, singleton, even and odd lengths, signed boundaries, the size bound, duplicates, unsorted values, and malformed lengths. The verifier also generates deterministic sorted arrays and checks all nine ports against an independent iterative shape oracle.

```sh
python3 benchmarks/verify_i64_array_scalar.py --algorithm bst_from_sorted_array --jobs 3 --elisa-compiler ../Elisa-compiler/bin/elisac-stage1
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm bst_from_sorted_array --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/b/bst_from_sorted_array/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/b/bst_from_sorted_array.c`](../../../c/b/bst_from_sorted_array.c) |
| C3 | [`c3/b/bst_from_sorted_array.c3`](../../../c3/b/bst_from_sorted_array.c3) |
| C++ | [`cpp/b/bst_from_sorted_array.cpp`](../../../cpp/b/bst_from_sorted_array.cpp) |
| Elisa | [`elisa/b/bst_from_sorted_array.elisa`](../../../elisa/b/bst_from_sorted_array.elisa) |
| Nim | [`nim/b/bst_from_sorted_array.nim`](../../../nim/b/bst_from_sorted_array.nim) |
| Odin | [`odin/b/bst_from_sorted_array.odin`](../../../odin/b/bst_from_sorted_array.odin) |
| Rust | [`rust/b/bst_from_sorted_array.rs`](../../../rust/b/bst_from_sorted_array.rs) |
| V | [`v/b/bst_from_sorted_array.v`](../../../v/b/bst_from_sorted_array.v) |
| Zig | [`zig/b/bst_from_sorted_array.zig`](../../../zig/b/bst_from_sorted_array.zig) |
