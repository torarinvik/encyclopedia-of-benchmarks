# Length of a list

The pinned Clojure file contains two equivalent implementations: one tail-recursively increments a counter while consuming the list, and another maps each element to one and sums. This benchmark compares the resulting length.

## Contract

Input is a list represented by up to 64 integers in `[0,100000]`. The output is its length, including zero for an empty list. Invalid input returns -1.

See [workload](workload.json), [independent oracle](../../length_of_list_oracle.py), and the pinned [Clojure source](https://github.com/TheAlgorithms/Clojure/blob/a9c5bec14928cb22fd4d69e951edf5bd15e16a18/src/data_structures/lists/length_of_list.clj).

| Language | Port |
|---|---|
| C | [`c/l/length_of_list.c`](../../../c/l/length_of_list.c) |
| C3 | [`c3/l/length_of_list.c3`](../../../c3/l/length_of_list.c3) |
| C++ | [`cpp/l/length_of_list.cpp`](../../../cpp/l/length_of_list.cpp) |
| Elisa | [`elisa/l/length_of_list.elisa`](../../../elisa/l/length_of_list.elisa) |
| Nim | [`nim/l/length_of_list.nim`](../../../nim/l/length_of_list.nim) |
| Odin | [`odin/l/length_of_list.odin`](../../../odin/l/length_of_list.odin) |
| Rust | [`rust/l/length_of_list.rs`](../../../rust/l/length_of_list.rs) |
| V | [`v/l/length_of_list.v`](../../../v/l/length_of_list.v) |
| Zig | [`zig/l/length_of_list.zig`](../../../zig/l/length_of_list.zig) |
