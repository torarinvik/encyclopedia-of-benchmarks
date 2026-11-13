# Dynamic ordered set with AVL order statistics

This package covers Library Checker’s dynamic `ordered_set` operation mix.
The local implementation uses an AVL tree augmented with subtree sizes. Its
balanced updates support rank selection, prefix counts, predecessor, and
successor in logarithmic tree height. This profile is bounded and uses a
weighted scalar checksum instead of emitting a variable-length query stream.

The operation mix is not present in the local ordered-tree packages:
[`avltree_unique_key_ops`](../../a/avltree_unique_key_ops/README.md) exposes
insert/search/delete and a final sorted snapshot;
[`binary_search_tree`](../../b/binary_search_tree/README.md) adds extrema and
size but not rank or neighbor queries; and
[`treap_unique_key_set`](../../t/treap_unique_key_set/README.md) reports only
the final set. The static [`wavelet_tree`](../../w/wavelet_tree/README.md) and
[`veb_tree`](../../v/veb_tree/README.md) do not offer this dynamic update and
order-statistic combination. The AVL implementation also keeps this package
algorithmically distinct from the existing randomized-priority treap.

## Contract

The exported scalar symbol is `ordered_set_avl_order_statistics`. Input is
`[N,Q,initial[N],(opcode,key)*Q]`:

- `0 <= N,Q <= 32`; initial keys are strictly increasing and in `0..1000`.
- Every operation key is in `0..1000`. Opcode 2 additionally requires a
  one-based rank of at least 1; a rank larger than the current set size returns
  `-1` as the query answer.
- Opcode `0` inserts a key if absent. Opcode `1` deletes a key if present.
  Both updates are idempotent.
- Opcode `2` returns the one-based k-th smallest key, or `-1` if that rank is
  larger than the set.
- Opcode `3` returns the number of keys less than or equal to the argument.
- Opcode `4` returns the greatest key less than or equal to the argument, or
  `-1` if none exists.
- Opcode `5` returns the least key greater than or equal to the argument, or
  `-1` if none exists.
- For query answers in operation order, the scalar result is
  `sum((query_index+1)*(answer+1))`. Thus missing-key answers contribute zero;
  no queries, including `Q=0`, return zero.
- Malformed input returns `-1`. Valid input length is exactly
  `2 + N + 2*Q`; the maximum valid and parseable lengths are 98 and 99 signed
  64-bit words. The maximum live set size is 64 and declared workspace is
  8192 bytes.

The primary oracle uses AVL rotations while maintaining both node height and
subtree cardinality. The independent oracle simulates the same operations in
a sorted list using binary-search insertion points. Both reject an initial
array that is not strictly increasing and validate every operation before
processing the trace.

## Workload and ports

[`workload.json`](workload.json) includes each query kind, idempotent updates,
empty results, malformed framing, and a maximum 98-word frame. The package
checker inventories source files and workload metadata without compiling or
running the ports.

| Language | Source |
| --- | --- |
| C | [`c/o/ordered_set_avl_order_statistics.c`](../../../c/o/ordered_set_avl_order_statistics.c) |
| C3 | [`c3/o/ordered_set_avl_order_statistics.c3`](../../../c3/o/ordered_set_avl_order_statistics.c3) |
| C++ | [`cpp/o/ordered_set_avl_order_statistics.cpp`](../../../cpp/o/ordered_set_avl_order_statistics.cpp) |
| Elisa | [`elisa/o/ordered_set_avl_order_statistics.elisa`](../../../elisa/o/ordered_set_avl_order_statistics.elisa) |
| Mojo | [`mojo/o/ordered_set_avl_order_statistics.mojo`](../../../mojo/o/ordered_set_avl_order_statistics.mojo) |
| Nim | [`nim/o/ordered_set_avl_order_statistics.nim`](../../../nim/o/ordered_set_avl_order_statistics.nim) |
| Odin | [`odin/o/ordered_set_avl_order_statistics.odin`](../../../odin/o/ordered_set_avl_order_statistics.odin) |
| Rust | [`rust/o/ordered_set_avl_order_statistics.rs`](../../../rust/o/ordered_set_avl_order_statistics.rs) |
| V | [`v/o/ordered_set_avl_order_statistics.v`](../../../v/o/ordered_set_avl_order_statistics.v) |
| Zig | [`zig/o/ordered_set_avl_order_statistics.zig`](../../../zig/o/ordered_set_avl_order_statistics.zig) |

## Provenance

The operation contract is from the official [Library Checker `ordered_set`
task](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/ordered_set/task.md).
The local AVL-with-subtree-size method, profile, oracles, fixtures, and ports
are written independently; no upstream implementation or test data is used.
The Library Checker repository is Apache-2.0 licensed; see
[`RIGHTS.md`](RIGHTS.md).
