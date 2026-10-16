# K-th next greater element

The pinned Python algorithm computes each entry's kth next-greater successor. Starting at the entry, it repeatedly finds the first later value strictly greater than the current value, then continues after that successor. Missing results are None. The bounded scalar result counts entries with a complete kth successor.

## Contract

Input is [k,array_values...], with k in 1..7, 1..7 values, and values in [-15,15]. Output is the number of input entries with a complete kth repeated strictly-greater successor; invalid input returns -1.

See [workload](workload.json), [oracle](../../kth_next_greater_element_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/stacks/kth_next_greater_element.py).

| Language | Port |
|---|---|
| C | [c/k/kth_next_greater_element.c](../../../c/k/kth_next_greater_element.c) |
| C3 | [c3/k/kth_next_greater_element.c3](../../../c3/k/kth_next_greater_element.c3) |
| C++ | [c++/k/kth_next_greater_element.cpp](../../../cpp/k/kth_next_greater_element.cpp) |
| Elisa | [elisa/k/kth_next_greater_element.elisa](../../../elisa/k/kth_next_greater_element.elisa) |
| Nim | [nim/k/kth_next_greater_element.nim](../../../nim/k/kth_next_greater_element.nim) |
| Odin | [odin/k/kth_next_greater_element.odin](../../../odin/k/kth_next_greater_element.odin) |
| Rust | [rust/k/kth_next_greater_element.rs](../../../rust/k/kth_next_greater_element.rs) |
| V | [v/k/kth_next_greater_element.v](../../../v/k/kth_next_greater_element.v) |
| Zig | [zig/k/kth_next_greater_element.zig](../../../zig/k/kth_next_greater_element.zig) |
