# Splay tree operation trace

This benchmark uses the common observable operations from the pinned Java and
Python splay trees. Valid source-semantic traces use absent keys for inserts
and delete only when the tree is nonempty. Duplicate insert and delete-on-empty
fixtures are included to check adapter rejection: the adapter returns `-1`
before calling either source implementation. The Java source throws for those
operations while the Python source ignores them, so they are not valid
source-semantic operations. The PHP implementation is not part of this
contract because its reviewed deletion path can lose a node.

## Input and output

The ABI is `i64_array_bytes_output`. Input is
`[operation_count, (opcode, key)...]`, with exactly two words per operation
and 0–64 operations. Keys are signed 32-bit integers. At most 32 keys may be
live at once.

- Opcode `0` inserts an absent key; its result tag is `-2`.
- Opcode `1` searches for a key and splays the found or last-accessed node; it
  emits `1` when found and `0` otherwise.
- Opcode `2` deletes a key from a nonempty tree; a missing key is a no-op and
  its result tag is `-3`.

The output is `[operation_count, operation_results..., final_key_count,
final_keys...]`. Final keys are in ascending order, matching Java's in-order
traversal and Python's iterator. Every word is a little-endian signed 64-bit
integer. At most 784 output bytes are produced. Invalid framing, out-of-range
keys, duplicate inserts, deleting from an empty tree, or exceeding 32 live
keys returns `-1`. A null output or insufficient capacity returns `-2`
without writes, after input validation.

The tree shape is not exposed by the shared API. Both sources splay after
searches, insertions, and nonempty deletions; the benchmark compares returned
search results and the final ordered key set. It does not include PHP's
divergent deletion behavior.

## Pinned sources and fixtures

The Java source is TheAlgorithms/Java
[`SplayTree.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/SplayTree.java)
at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`. The Python source is
TheAlgorithms/Python
[`splay_tree.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/splay_tree.py)
at commit `e1a2a8b016001309a73d5fec4818c35cca139795`. The fixtures and
ABI cases are in [workload.json](workload.json); the independent oracle is
[`benchmarks/splay_tree_oracle.py`](../../splay_tree_oracle.py).
