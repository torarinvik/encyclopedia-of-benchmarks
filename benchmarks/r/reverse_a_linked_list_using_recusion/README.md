# Reverse a Linked List Using Recursion

Recursively reverse a singly linked list by rewiring its links, then emit values from the new head onward.

## Contract

- ABI: `i64_array_bytes_output`.
- Input is `[n, value_0, ..., value_(n-1)]`, with exact length `n + 1` and `2 <= n <= 64`.
- Values must fit signed i32. Invalid framing, count, or values return `-1` before output storage is checked.
- Build a fresh list in input order and recursively reverse its links using the pinned `reverse(p, q)` algorithm. Emit the values from the resulting head.
- Return the reversed values as little-endian signed i32 bytes, for `4*n` bytes total (maximum 256 bytes).
- Null output or insufficient capacity returns `-2` without writes. Exact output capacity succeeds.

The bounded ports use node indices in place of allocated pointers. A recursive helper follows the next link to the tail, then rewires each predecessor link while unwinding. The oracle reverses a Python array independently. Recursion depth is at most 64.

## Workload

[`workload.json`](workload.json) covers the pinned six-node example, two-node and maximum-size lists, signed-i32 boundaries, duplicate values, malformed input, null output, and insufficient capacity. See the [oracle](../../reverse_a_linked_list_using_recusion_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/reverse_a_linked_list_using_recusion.c`](../../../c/r/reverse_a_linked_list_using_recusion.c) |
| C3 | [`c3/r/reverse_a_linked_list_using_recusion.c3`](../../../c3/r/reverse_a_linked_list_using_recusion.c3) |
| C++ | [`cpp/r/reverse_a_linked_list_using_recusion.cpp`](../../../cpp/r/reverse_a_linked_list_using_recusion.cpp) |
| Elisa | [`elisa/r/reverse_a_linked_list_using_recusion.elisa`](../../../elisa/r/reverse_a_linked_list_using_recusion.elisa) |
| Nim | [`nim/r/reverse_a_linked_list_using_recusion.nim`](../../../nim/r/reverse_a_linked_list_using_recusion.nim) |
| Odin | [`odin/r/reverse_a_linked_list_using_recusion.odin`](../../../odin/r/reverse_a_linked_list_using_recusion.odin) |
| Rust | [`rust/r/reverse_a_linked_list_using_recusion.rs`](../../../rust/r/reverse_a_linked_list_using_recusion.rs) |
| V | [`v/r/reverse_a_linked_list_using_recusion.v`](../../../v/r/reverse_a_linked_list_using_recusion.v) |
| Zig | [`zig/r/reverse_a_linked_list_using_recusion.zig`](../../../zig/r/reverse_a_linked_list_using_recusion.zig) |

## Pinned sources

- [TheAlgorithms/C-Plus-Plus recursive reversal](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/operations_on_datastructures/reverse_a_linked_list_using_recusion.cpp) at `fdcc29b0ac2848e9d1a8d926e171cc5b39f97759`.
- [TheAlgorithms/C-Plus-Plus-1 recursive reversal](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/operations_on_datastructures/reverse_a_linked_list_using_recusion.cpp) at `0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680`.

The two pinned files are byte-identical. The source calls the recursive helper with the first two nodes and dereferences both, so the benchmark domain begins at two nodes. The benchmark omits each source file's self-test entry point and global head variable; the bounded adapter represents the head as an index.

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm reverse_a_linked_list_using_recusion --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm reverse_a_linked_list_using_recusion
```
