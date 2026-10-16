# K-th element in a list

The pinned Clojure file provides two equivalent implementations: one recursively consumes the list until the 1-based position reaches one, and the other drops `k-1` elements and takes the first. The benchmark uses a bounded integer list and the same 1-based selection rule.

## Contract

Input is `[n,k,x0,...]`, with 1..16 values, `1 <= k <= n`, and each value in [-10000,10000]. The result is the element at one-based position k. Malformed inputs return -1.

See [workload](workload.json), [oracle](../../kth_element_in_a_list_oracle.py), and pinned [Clojure source](https://github.com/TheAlgorithms/Clojure/blob/a9c5bec14928cb22fd4d69e951edf5bd15e16a18/src/data_structures/lists/kth_element_in_a_list.clj).

| Language | Port |
|---|---|
| C | c/k/kth_element_in_a_list.c |
| C3 | c3/k/kth_element_in_a_list.c3 |
| C++ | cpp/k/kth_element_in_a_list.cpp |
| Elisa | elisa/k/kth_element_in_a_list.elisa |
| Nim | nim/k/kth_element_in_a_list.nim |
| Odin | odin/k/kth_element_in_a_list.odin |
| Rust | rust/k/kth_element_in_a_list.rs |
| V | v/k/kth_element_in_a_list.v |
| Zig | zig/k/kth_element_in_a_list.zig |
