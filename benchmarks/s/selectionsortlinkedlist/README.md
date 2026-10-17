# Selection sort on a linked list

Sort a bounded singly linked list by repeatedly locating the minimum node in the unsorted suffix and relinking that node into the sorted prefix. This is the pointer-relinking algorithm from the pinned C++ source, and is distinct from array selection sort.

## Contract

- Input uses the `i64_array_bytes_output` ABI and is exactly `[n, value_0, ..., value_(n-1)]`. `n` is 1–64, and each value is a signed i32 carried in an i64 slot.
- The output contains all values in ascending signed order, encoded as one little-endian signed i32 per node. Duplicates are retained. There is no count header; success returns `4*n` bytes, up to 256.
- Invalid or null input returns `-1`. After full input validation, a null output pointer or insufficient capacity returns `-2` without writing. Valid inputs always produce at least four output bytes.
- Ports use bounded node arrays with integer links, applying the source's list-pointer updates rather than swapping values in an array. The linked structure is traversed after sorting to serialize the result.
- The source's sort method requires a nonnull head. Its demo returns immediately for `n=0`, so the bounded ABI uses `n=1..64` and represents empty/null input as invalid.

The pinned implementation is [`selectionsortlinkedlist.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/operations_on_datastructures/selectionsortlinkedlist.cpp) at commit `fdcc29b0ac2848e9d1a8d926e171cc5b39f97759`; its sort routine is `my_selection_sort_linked_list(node *&head)`.

`workload.json` covers the head and interior node-relinking paths, duplicates, signed boundaries, the maximum list size, malformed frames, null pointers, and short output capacity. `benchmarks/selectionsortlinkedlist_oracle.py` uses an independent built-in ascending sort for the observable sequence.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/selectionsortlinkedlist.c`](../../../c/s/selectionsortlinkedlist.c) |
| C3 | [`c3/s/selectionsortlinkedlist.c3`](../../../c3/s/selectionsortlinkedlist.c3) |
| C++ | [`cpp/s/selectionsortlinkedlist.cpp`](../../../cpp/s/selectionsortlinkedlist.cpp) |
| Elisa | [`elisa/s/selectionsortlinkedlist.elisa`](../../../elisa/s/selectionsortlinkedlist.elisa) |
| Nim | [`nim/s/selectionsortlinkedlist.nim`](../../../nim/s/selectionsortlinkedlist.nim) |
| Odin | [`odin/s/selectionsortlinkedlist.odin`](../../../odin/s/selectionsortlinkedlist.odin) |
| Rust | [`rust/s/selectionsortlinkedlist.rs`](../../../rust/s/selectionsortlinkedlist.rs) |
| V | [`v/s/selectionsortlinkedlist.v`](../../../v/s/selectionsortlinkedlist.v) |
| Zig | [`zig/s/selectionsortlinkedlist.zig`](../../../zig/s/selectionsortlinkedlist.zig) |
