# Singly linked list operation trace

This benchmark compares the pinned generic Go `Singly` list operations on bounded signed integer values. It models the list state with a sequence in the oracle and returns both the final list and one result pair per operation.

## Contract

The ABI is `i64_array_bytes_output`. Input is `[initial_count, operation_count, initial_values..., operation_stream...]`. Initial and inserted values are in [-1000000, 1000000]. There are at most 32 initial nodes and 64 operations; the list can therefore hold at most 96 nodes. Each operation begins with an opcode: 0 adds a value at the beginning, 1 adds a value at the end, 2 deletes the beginning, 3 deletes the end, 4 deletes a one-based position, 5 reverses the full list, and 6 reverses an inclusive one-based range `[left, right]`.

Opcodes 0, 1, and 4 carry one argument; opcode 6 carries two; opcodes 2, 3, and 5 carry none. The packed input must contain exactly the values described by its counts and operation opcodes. List-position deletion accepts positions 1 through `current_length + 1` when the list is nonempty. The pinned `DelByPos` routes `current_length + 1` to tail deletion; its ordinary loop also deletes the tail at `current_length`. On an empty list, position 1 returns `(0, false)`. Position zero is excluded because the pinned implementation can panic on a nonempty list. Range reversal requires `1 <= left <= right <= current_length`.

For every operation, the output records a pair `(success, value)`. Additions, full reversal, and valid range reversal record `(1, 0)`; deletions record their returned `(value, success)` as `(success, value)`, with `(0, 0)` for an empty-list deletion. The complete output is little-endian signed 64-bit words in this layout: `[final_count, final_values..., operation_count, (success, value) per operation]`. Success returns the number of output bytes. Malformed framing, out-of-range values, unknown opcodes, or positions/ranges outside this contract return -1. For valid input, null or short output returns -2. Input validation precedes output checks, and errors leave the buffer untouched.

## Pinned source

- Go `Singly`: https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/structure/linkedlist/singlylinkedlist.go

The benchmark covers the list mutation operations and their return values. The source's console display and generic payload support are outside the packed integer contract.

## Workload and oracle

- Workload: `workload.json`
- Oracle: `../../singlylinkedlist_oracle.py`

## Ports

| Language | Source |
| --- | --- |
| C | [`c/s/singlylinkedlist.c`](../../../c/s/singlylinkedlist.c) |
| C3 | [`c3/s/singlylinkedlist.c3`](../../../c3/s/singlylinkedlist.c3) |
| C++ | [`cpp/s/singlylinkedlist.cpp`](../../../cpp/s/singlylinkedlist.cpp) |
| Elisa | [`elisa/s/singlylinkedlist.elisa`](../../../elisa/s/singlylinkedlist.elisa) |
| Nim | [`nim/s/singlylinkedlist.nim`](../../../nim/s/singlylinkedlist.nim) |
| Odin | [`odin/s/singlylinkedlist.odin`](../../../odin/s/singlylinkedlist.odin) |
| Rust | [`rust/s/singlylinkedlist.rs`](../../../rust/s/singlylinkedlist.rs) |
| V | [`v/s/singlylinkedlist.v`](../../../v/s/singlylinkedlist.v) |
| Zig | [`zig/s/singlylinkedlist.zig`](../../../zig/s/singlylinkedlist.zig) |
