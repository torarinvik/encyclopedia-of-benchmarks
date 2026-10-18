# Sorted linked-list insert, search, and delete

This benchmark measures one core operation on the pinned sorted linked-list
implementations. Each call starts from a supplied sorted list and performs one
insert, search, or delete. Python `merge(self)`, `remove_duplicates`, display,
and iteration helpers are outside the contract.

## Contract

Input is `[initial_count, initial_values..., operation, key]`. `initial_count`
is 0 through 16. Initial values and `key` are signed 32-bit integers; initial
values must be strictly increasing, so they are distinct. Operation 0 inserts
`key`, operation 1 searches for it, and operation 2 deletes its first
occurrence. Insert is valid only when `key` is absent from the initial list.
This keeps keys distinct and avoids the pinned Python dataclass comparison
failure for a duplicate key equal to a non-singleton head. Search and delete
may use a present or absent key.

The input has exactly `initial_count + 3` signed-i64 words. Its maximum valid
length is 19 words and its maximum parseable length is 20 for a trailing-word
probe. Insert returns the updated list, preserving ascending order and
inserting before the first larger value. Search returns whether the key is
present. Delete removes the first matching node and updates the head or tail
when needed.

Output is little-endian signed-i64 words, with a layout determined by the
operation: insert returns `[new_count, sorted_values...]`; search returns
`[found]` where found is 0 or 1; delete returns
`[deleted, new_count, resulting_values...]`. The maximum output is 18 words,
or 144 bytes. A valid call returns the number of output bytes written.

Malformed framing, invalid operation codes, values outside signed-i32 range,
non-increasing initial values, or an insert of an existing key returns `-1`
before output checks. A null output pointer or insufficient byte capacity
returns `-2` after input validation. Error calls write no output bytes.

The independent oracle is [`../../sorted_linked_list_oracle.py`](../../sorted_linked_list_oracle.py).
The workload covers insertion at the head, middle, and tail, empty-list
insertion, found and missing searches, deletion at each position, missing
deletion, maximum output, malformed input, and output-capacity edges.

## Pinned sources

- Java [`SortedLinkedList.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/lists/SortedLinkedList.java), `insert`, `search`, and `delete`.
- Python [`sorted_linked_list.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/linked_list/sorted_linked_list.py), `insert`, `search`, and `delete`.

## Language ports

| Language | Port |
|---|---|
| C | [`c/s/sorted_linked_list.c`](../../../c/s/sorted_linked_list.c) |
| C3 | [`c3/s/sorted_linked_list.c3`](../../../c3/s/sorted_linked_list.c3) |
| C++ | [`cpp/s/sorted_linked_list.cpp`](../../../cpp/s/sorted_linked_list.cpp) |
| Elisa | [`elisa/s/sorted_linked_list.elisa`](../../../elisa/s/sorted_linked_list.elisa) |
| Nim | [`nim/s/sorted_linked_list.nim`](../../../nim/s/sorted_linked_list.nim) |
| Odin | [`odin/s/sorted_linked_list.odin`](../../../odin/s/sorted_linked_list.odin) |
| Rust | [`rust/s/sorted_linked_list.rs`](../../../rust/s/sorted_linked_list.rs) |
| V | [`v/s/sorted_linked_list.v`](../../../v/s/sorted_linked_list.v) |
| Zig | [`zig/s/sorted_linked_list.zig`](../../../zig/s/sorted_linked_list.zig) |
