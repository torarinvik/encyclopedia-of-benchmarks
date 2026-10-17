# Linked list implementation using an array

This benchmark models the logical list built by the pinned C++ array-backed
linked-list implementation. The source maintains a 100-slot node pool with a
free-list, inserts at the beginning, inserts at the end, and displays values
from the logical head to tail. Both pinned C++ copies listed below are
identical.

## Contract

- ABI: `i64_array_bytes_output`. Input is
  `[operation_count, (opcode, value)*]`, with exactly two signed-i64 cells per
  operation. The operation count is 0..100 and each value must fit signed i32.
  The benchmark starts with an empty list and all 100 pool nodes available.
- Opcode `0` inserts the value at the beginning. Opcode `1` inserts it at the
  end, and is valid only when the list is nonempty. The source's end-insertion
  routine dereferences the head before handling an empty list, so this trace
  restriction keeps the call within its safe domain. Duplicate values are
  allowed. There are no delete operations in the pinned program's menu.
- The result is the final logical list in head-to-tail order, encoded as
  little-endian signed-i32 values with a leading signed-i32 length:
  `[length, values...]`. Success returns the output byte count. The maximum
  list length is 100 and the maximum output is 404 bytes.
- Invalid framing, operation count, opcode, value, an end insertion into an
  empty list, or more than 100 insertions returns `-1`. The entire trace is
  validated before checking output storage. A null output pointer or capacity
  below the required byte count returns `-2` without writing. A null input
  pointer returns `-1`, including at length zero. The maximum valid input is
  201 i64 cells; 202 cells are parseable for malformed trailing-field checks.

## Workload and sources

[`workload.json`](workload.json) covers empty and mixed traces, head/tail order,
duplicate and signed-boundary values, empty-list end insertion, malformed
framing and opcodes, pool capacity, and output-buffer behavior. The independent
oracle is [`benchmarks/linkedlist_implentation_usingarray_oracle.py`](../../linkedlist_implentation_usingarray_oracle.py).

- Primary pinned source: [TheAlgorithms/C-Plus-Plus `linkedlist_implentation_usingarray.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/linkedlist_implentation_usingarray.cpp)
- Identical corroborating copy: [TheAlgorithms/C-Plus-Plus-1 `linkedlist_implentation_usingarray.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/data_structures/linkedlist_implentation_usingarray.cpp)

## Language ports

| Language | Port |
| --- | --- |
| C | [`c/l/linkedlist_implentation_usingarray.c`](../../../c/l/linkedlist_implentation_usingarray.c) |
| C3 | [`c3/l/linkedlist_implentation_usingarray.c3`](../../../c3/l/linkedlist_implentation_usingarray.c3) |
| C++ | [`cpp/l/linkedlist_implentation_usingarray.cpp`](../../../cpp/l/linkedlist_implentation_usingarray.cpp) |
| Elisa | [`elisa/l/linkedlist_implentation_usingarray.elisa`](../../../elisa/l/linkedlist_implentation_usingarray.elisa) |
| Nim | [`nim/l/linkedlist_implentation_usingarray.nim`](../../../nim/l/linkedlist_implentation_usingarray.nim) |
| Odin | [`odin/l/linkedlist_implentation_usingarray.odin`](../../../odin/l/linkedlist_implentation_usingarray.odin) |
| Rust | [`rust/l/linkedlist_implentation_usingarray.rs`](../../../rust/l/linkedlist_implentation_usingarray.rs) |
| V | [`v/l/linkedlist_implentation_usingarray.v`](../../../v/l/linkedlist_implentation_usingarray.v) |
| Zig | [`zig/l/linkedlist_implentation_usingarray.zig`](../../../zig/l/linkedlist_implentation_usingarray.zig) |
