# Two-pointer linked-list techniques

This benchmark covers the three operations in the pinned source: Floyd cycle detection by node identity, selecting the second middle node for an even-length list, and finding the 1-based n-th node from the end.

## Contract

- Input is the signed-i64 vector `[op, n, cycle_target, k, value_0, ..., value_(n-1)]`, with exact length `4+n`, `n` in `0..128`, and values in `[-1,000,000,1,000,000]`.
- Nodes are represented by their vector indices. A nonempty list starts at index 0, and each node points to the next index. The tail points to `cycle_target`: `-1` for a null next pointer, or `0..n-1` for a cycle. For an empty list, only `cycle_target=-1` is valid.
- Operation 0 runs Floyd's slow/fast pointer cycle detection. It allows a cycle target in range, requires `k=0`, and returns 1 for a cycle and 0 otherwise.
- Operation 1 runs the slow/fast middle traversal on an acyclic list, requires `k=0`, and returns `value+1,000,001` for the second middle (including the unique middle of an odd list). An empty list returns -2, matching the source's null result.
- Operation 2 runs the lead/lag n-th-from-end traversal on an acyclic list. `k` is any signed-i64 input word, then the operation returns -1 for `k<1` or `k>n` (which includes every `k` for an empty list). A valid result is encoded as `value+3,000,002`.
- Invalid length, operation, node count, value, cycle encoding, or required dummy `k` returns -1. Result bands are disjoint: cycle results 0/1, empty-middle -2, middle values 1..2,000,001, and n-th-from-end values 2,000,002..4,000,002.
- Implementations traverse the index-linked list using the specified pointer algorithms; they do not calculate the answer directly from the vector position.

The independent oracle is [`benchmarks/two_pointer_technique_oracle.py`](../../two_pointer_technique_oracle.py). The workload includes odd/even and empty lists, cycles at different nodes, endpoint `k` values, invalid `k` values including signed-i64 extremes, and malformed encodings.

Pinned source: [TheAlgorithms/R `two_pointer_technique.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/linked_list_algorithms/two_pointer_technique.r), commit `f65344fabeea0ae33c1ca321af709447c1a8a4c2`.

Build and record with the `i64_array_scalar` ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm two_pointer_technique --language c
python3 benchmarks/run_i64_array_scalar.py --algorithm two_pointer_technique
```

| Language | Port |
| --- | --- |
| C | [`c/t/two_pointer_technique.c`](../../../c/t/two_pointer_technique.c) |
| C3 | [`c3/t/two_pointer_technique.c3`](../../../c3/t/two_pointer_technique.c3) |
| C++ | [`cpp/t/two_pointer_technique.cpp`](../../../cpp/t/two_pointer_technique.cpp) |
| Elisa | [`elisa/t/two_pointer_technique.elisa`](../../../elisa/t/two_pointer_technique.elisa) |
| Nim | [`nim/t/two_pointer_technique.nim`](../../../nim/t/two_pointer_technique.nim) |
| Odin | [`odin/t/two_pointer_technique.odin`](../../../odin/t/two_pointer_technique.odin) |
| Rust | [`rust/t/two_pointer_technique.rs`](../../../rust/t/two_pointer_technique.rs) |
| V | [`v/t/two_pointer_technique.v`](../../../v/t/two_pointer_technique.v) |
| Zig | [`zig/t/two_pointer_technique.zig`](../../../zig/t/two_pointer_technique.zig) |
