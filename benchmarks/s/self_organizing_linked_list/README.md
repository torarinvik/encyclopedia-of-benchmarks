# Self-organizing linked list

This benchmark follows the pinned Java `SelfOrganizingLinkedList` and its
move-to-front search strategy. Insertion appends a node. A successful search
moves the first matching node to the head; an unsuccessful search leaves the
list unchanged.

## Contract

- ABI: `i64_array_bytes_output`. Input is
  `[operation_count, (opcode, value)*]`, with exactly two signed-i64 cells per
  operation. The operation count is 0..64 and values fit signed i32. The list
  starts empty and retains duplicate values.
- Opcode `0` inserts `value` at the tail and emits `[0, 0]`. Opcode `1` searches
  for `value` and emits `[1, 1, found]`, where `found` is 1 or 0. Search uses
  the first equal value in head-to-tail order; a hit moves that node to the
  head, while a miss does not change the list.
- After the operations, the output contains a final snapshot record
  `[2, list_length, values...]`, with values in head-to-tail order. All trace
  fields are signed-i64 little-endian values; i32 payloads are sign-extended
  into the output fields. The function returns the output byte count.
- Invalid framing, operation counts, opcodes, or values return `-1`. The whole
  trace is validated before checking output storage. A null output pointer or
  insufficient capacity returns `-2` without writing. A null input pointer
  returns `-1`, including at length zero. The maximum valid input is 129 i64
  cells; 130 cells are parseable for malformed trailing-field checks. The
  maximum output is 194 signed-i64 fields, or 1,552 bytes.

## Workload and source

[`workload.json`](workload.json) covers insertion order, head and interior
search hits, misses, duplicate-value first-match behavior, signed-i32
boundaries, malformed traces, the 64-operation bound, and output-buffer cases.
The independent oracle is
[`self_organizing_linked_list_oracle.py`](../../self_organizing_linked_list_oracle.py).

- Pinned Java source: [SelfOrganizingLinkedList.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/lists/SelfOrganizingLinkedList.java)

## Language ports

| Language | Port |
| --- | --- |
| C | [`c/s/self_organizing_linked_list.c`](../../../c/s/self_organizing_linked_list.c) |
| C3 | [`c3/s/self_organizing_linked_list.c3`](../../../c3/s/self_organizing_linked_list.c3) |
| C++ | [`cpp/s/self_organizing_linked_list.cpp`](../../../cpp/s/self_organizing_linked_list.cpp) |
| Elisa | [`elisa/s/self_organizing_linked_list.elisa`](../../../elisa/s/self_organizing_linked_list.elisa) |
| Nim | [`nim/s/self_organizing_linked_list.nim`](../../../nim/s/self_organizing_linked_list.nim) |
| Odin | [`odin/s/self_organizing_linked_list.odin`](../../../odin/s/self_organizing_linked_list.odin) |
| Rust | [`rust/s/self_organizing_linked_list.rs`](../../../rust/s/self_organizing_linked_list.rs) |
| V | [`v/s/self_organizing_linked_list.v`](../../../v/s/self_organizing_linked_list.v) |
| Zig | [`zig/s/self_organizing_linked_list.zig`](../../../zig/s/self_organizing_linked_list.zig) |
