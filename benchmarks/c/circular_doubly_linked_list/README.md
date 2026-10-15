# Circular doubly linked list operation trace

The pinned C and Java sources implement circular doubly linked lists. The existing [`doubly_linked_list`](../../d/doubly_linked_list/README.md) trace already covers end insertion and removal, remove-by-value, membership, size, and forward/reverse traversal. This trace adds the operations that distinguish the circular list contract: indexed access wraps modulo the current length, and positional removal uses a zero-based index.

## Contract

The `i64_array_scalar` function accepts zero to 1,024 signed 64-bit values encoded as `[opcode, payload]` pairs, for up to 512 operations:

- `0`: append a value from -1,000,000 through 1,000,000
- `1`: prepend a value in the same range
- `2`: remove and return the first value, with payload zero
- `3`: remove and return the last value, with payload zero
- `4`: remove the first matching value, returning `1` if found and `0` otherwise
- `5`: report whether a value is present, returning `1` or `0`
- `6`: report the list length, with payload zero
- `7`: return the value at `payload modulo length`; payload is 0 through 1,000,000
- `8`: remove and return the value at the zero-based payload index

The list capacity is 256. Odd-length input, an unknown operation, an out-of-range value or index, a nonzero payload for operations 2, 3, or 6, an empty pop or indexed read, an invalid positional removal, overflow, or input longer than 1,024 values returns `-1`. Empty input is valid. The fixed node pool uses a circular sentinel with both forward and backward links; removed nodes are reused.

Each observed result contributes `(operation_index + 1) * (observed_value + 1,000,000)` to the checksum. The remaining values are then included in forward and reverse order with one-based weights, so both link directions and list order affect the result. Valid checksums are nonnegative and fit signed 64-bit.

[`workload.json`](workload.json) includes modular wraparound, singleton and multi-node positional removal, duplicate values, end operations, empty-list errors, malformed traces, and the capacity boundary.

## Implementations

The nine portable implementations are in [`c/c/circular_doubly_linked_list.c`](../../../c/c/circular_doubly_linked_list.c), [`c3/c/circular_doubly_linked_list.c3`](../../../c3/c/circular_doubly_linked_list.c3), [`cpp/c/circular_doubly_linked_list.cpp`](../../../cpp/c/circular_doubly_linked_list.cpp), [`elisa/c/circular_doubly_linked_list.elisa`](../../../elisa/c/circular_doubly_linked_list.elisa), [`nim/c/circular_doubly_linked_list.nim`](../../../nim/c/circular_doubly_linked_list.nim), [`odin/c/circular_doubly_linked_list.odin`](../../../odin/c/circular_doubly_linked_list.odin), [`rust/c/circular_doubly_linked_list.rs`](../../../rust/c/circular_doubly_linked_list.rs), [`v/c/circular_doubly_linked_list.v`](../../../v/c/circular_doubly_linked_list.v), and [`zig/c/circular_doubly_linked_list.zig`](../../../zig/c/circular_doubly_linked_list.zig).

## Upstream references

- [C circular doubly linked list](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/linked_list/circular_doubly_linked_list.c)
- [Java circular doubly linked list](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/lists/CircularDoublyLinkedList.java)
