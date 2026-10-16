# Iterating through submasks

This benchmark ports the pinned Python loop that enumerates nonzero submasks in descending order using `(submask - 1) & mask`. The package compares the returned list length, avoiding the large list output in the scalar benchmark ABI.

## Contract

Input is a single signed integer mask in `[1, 4095]`, so at most 12 bits are set and enumeration stays bounded. The result is the number of nonzero submasks; zero is excluded by the pinned source. Invalid input returns -1.

See the [workload](workload.json), [independent oracle](../../iterating_through_submasks_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/iterating_through_submasks.py).

| Language | Port |
|---|---|
| C | [`c/i/iterating_through_submasks.c`](../../../c/i/iterating_through_submasks.c) |
| C3 | [`c3/i/iterating_through_submasks.c3`](../../../c3/i/iterating_through_submasks.c3) |
| C++ | [`cpp/i/iterating_through_submasks.cpp`](../../../cpp/i/iterating_through_submasks.cpp) |
| Elisa | [`elisa/i/iterating_through_submasks.elisa`](../../../elisa/i/iterating_through_submasks.elisa) |
| Nim | [`nim/i/iterating_through_submasks.nim`](../../../nim/i/iterating_through_submasks.nim) |
| Odin | [`odin/i/iterating_through_submasks.odin`](../../../odin/i/iterating_through_submasks.odin) |
| Rust | [`rust/i/iterating_through_submasks.rs`](../../../rust/i/iterating_through_submasks.rs) |
| V | [`v/i/iterating_through_submasks.v`](../../../v/i/iterating_through_submasks.v) |
| Zig | [`zig/i/iterating_through_submasks.zig`](../../../zig/i/iterating_through_submasks.zig) |
