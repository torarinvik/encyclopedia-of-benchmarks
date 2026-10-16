# Last item in a list

This benchmark ports the pinned Clojure recursive `get-last-item`: destructure the head and tail, return the head when the tail is empty, otherwise recur on the tail. The benchmark returns the final element.

## Contract

Input is a list represented as up to 64 integers in `[0,100000]`. For an empty list, the source returns nil; the scalar benchmark maps nil to -1. Invalid input also returns -1.

See [workload](workload.json), [independent oracle](../../last_item_in_a_list_oracle.py), and the pinned [Clojure source](https://github.com/TheAlgorithms/Clojure/blob/a9c5bec14928cb22fd4d69e951edf5bd15e16a18/src/data_structures/lists/last_item_in_a_list.clj).

| Language | Port |
|---|---|
| C | [`c/l/last_item_in_a_list.c`](../../../c/l/last_item_in_a_list.c) |
| C3 | [`c3/l/last_item_in_a_list.c3`](../../../c3/l/last_item_in_a_list.c3) |
| C++ | [`cpp/l/last_item_in_a_list.cpp`](../../../cpp/l/last_item_in_a_list.cpp) |
| Elisa | [`elisa/l/last_item_in_a_list.elisa`](../../../elisa/l/last_item_in_a_list.elisa) |
| Nim | [`nim/l/last_item_in_a_list.nim`](../../../nim/l/last_item_in_a_list.nim) |
| Odin | [`odin/l/last_item_in_a_list.odin`](../../../odin/l/last_item_in_a_list.odin) |
| Rust | [`rust/l/last_item_in_a_list.rs`](../../../rust/l/last_item_in_a_list.rs) |
| V | [`v/l/last_item_in_a_list.v`](../../../v/l/last_item_in_a_list.v) |
| Zig | [`zig/l/last_item_in_a_list.zig`](../../../zig/l/last_item_in_a_list.zig) |
