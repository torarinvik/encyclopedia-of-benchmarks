# Largest divisible subset

This benchmark ports the pinned Python dynamic program. The source sorts the input, computes the longest chain whose each later value is divisible by its predecessor, then reconstructs one chain. The benchmark returns only the chain length.

## Contract

Input is an array of 0 to 64 positive integers in `[1, 50000]`. Positive values keep the divisible-chain relation meaningful and bounded; duplicates are retained, matching the source behavior. The result is the longest divisible subset length; invalid input returns -1.

See [workload](workload.json), [independent oracle](../../largest_divisible_subset_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/largest_divisible_subset.py).

| Language | Port |
|---|---|
| C | [`c/l/largest_divisible_subset.c`](../../../c/l/largest_divisible_subset.c) |
| C3 | [`c3/l/largest_divisible_subset.c3`](../../../c3/l/largest_divisible_subset.c3) |
| C++ | [`cpp/l/largest_divisible_subset.cpp`](../../../cpp/l/largest_divisible_subset.cpp) |
| Elisa | [`elisa/l/largest_divisible_subset.elisa`](../../../elisa/l/largest_divisible_subset.elisa) |
| Nim | [`nim/l/largest_divisible_subset.nim`](../../../nim/l/largest_divisible_subset.nim) |
| Odin | [`odin/l/largest_divisible_subset.odin`](../../../odin/l/largest_divisible_subset.odin) |
| Rust | [`rust/l/largest_divisible_subset.rs`](../../../rust/l/largest_divisible_subset.rs) |
| V | [`v/l/largest_divisible_subset.v`](../../../v/l/largest_divisible_subset.v) |
| Zig | [`zig/l/largest_divisible_subset.zig`](../../../zig/l/largest_divisible_subset.zig) |
