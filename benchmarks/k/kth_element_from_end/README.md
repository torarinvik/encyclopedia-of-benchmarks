# K-th element from the end

This benchmark ports the pinned Python linked list's two-pointer lookup. Its `position` is one-based: position 1 returns the tail. The routine advances a fast pointer by k nodes, then advances slow and fast together until fast reaches the end.

## Contract

Input is `[position, traversal_values...]`, with at most 64 values in `[0,100000]`. Valid positions are 1 through the number of values. Output is the selected value; when the source returns `None` or the input is invalid, the scalar ABI uses -1.

See [workload](workload.json), [independent oracle](../../kth_element_from_end_oracle.py), and the pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/linked_list/kth_element_from_end.py).

| Language | Port |
|---|---|
| C | [`c/k/kth_element_from_end.c`](../../../c/k/kth_element_from_end.c) |
| C3 | [`c3/k/kth_element_from_end.c3`](../../../c3/k/kth_element_from_end.c3) |
| C++ | [`cpp/k/kth_element_from_end.cpp`](../../../cpp/k/kth_element_from_end.cpp) |
| Elisa | [`elisa/k/kth_element_from_end.elisa`](../../../elisa/k/kth_element_from_end.elisa) |
| Nim | [`nim/k/kth_element_from_end.nim`](../../../nim/k/kth_element_from_end.nim) |
| Odin | [`odin/k/kth_element_from_end.odin`](../../../odin/k/kth_element_from_end.odin) |
| Rust | [`rust/k/kth_element_from_end.rs`](../../../rust/k/kth_element_from_end.rs) |
| V | [`v/k/kth_element_from_end.v`](../../../v/k/kth_element_from_end.v) |
| Zig | [`zig/k/kth_element_from_end.zig`](../../../zig/k/kth_element_from_end.zig) |
