# Pairwise iteration

The pinned Python `pairwise_iteration_tee` uses `itertools.tee`, advances one iterator by one element, then zips the iterators to yield adjacent pairs. Its second implementation, `pairwise_iteration_comprehension`, has the same behavior with its default `step=1`; the benchmark fixes that default and uses signed integer sequences.

## Contract

Input is `[item_count, item0, ...]` with 0 to 128 items in `[-1,000,000, 1,000,000]`. Output is the adjacent pairs flattened in order and encoded as signed little-endian i64 words; the function returns bytes written. Invalid input returns `-1`; insufficient capacity returns `-2`.

See [`workload.json`](workload.json) and the runtime [oracle](../../pairwise_iteration_oracle.py). Pinned source: [TheAlgorithms/Python `pairwise_iteration.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/arrays/pairwise_iteration.py).

| Language | Port |
|---|---|
| C | [`c/p/pairwise_iteration.c`](../../../c/p/pairwise_iteration.c) |
| C3 | [`c3/p/pairwise_iteration.c3`](../../../c3/p/pairwise_iteration.c3) |
| C++ | [`cpp/p/pairwise_iteration.cpp`](../../../cpp/p/pairwise_iteration.cpp) |
| Elisa | [`elisa/p/pairwise_iteration.elisa`](../../../elisa/p/pairwise_iteration.elisa) |
| Nim | [`nim/p/pairwise_iteration.nim`](../../../nim/p/pairwise_iteration.nim) |
| Odin | [`odin/p/pairwise_iteration.odin`](../../../odin/p/pairwise_iteration.odin) |
| Rust | [`rust/p/pairwise_iteration.rs`](../../../rust/p/pairwise_iteration.rs) |
| V | [`v/p/pairwise_iteration.v`](../../../v/p/pairwise_iteration.v) |
| Zig | [`zig/p/pairwise_iteration.zig`](../../../zig/p/pairwise_iteration.zig) |
