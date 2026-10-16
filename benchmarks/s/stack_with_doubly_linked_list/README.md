# Stack with a doubly linked list

This package ports TheAlgorithms/Python's `Stack` behavior using a bounded trace ABI. Each push creates a node at the head, and pop/top access the head; len traverses the linked nodes.

## Contract

The input is `[op_count, opcode, (value for push), ...]`. There are at most 64 operations, push values are signed 32-bit integers, and the packed stream must end exactly after the final operation. Opcode 1 pushes a value; 2 pops; 3 reads the top; 4 returns the length. Push returns None. Empty pop/top return None.

The output contains one 24-byte record per operation: opcode, result tag, and value as signed i64 little-endian words. Tags are 0 for integer and 2 for None; other shared tag values are reserved under this contract. Maximum output is 1,536 bytes. Invalid input returns -1; null output or insufficient capacity returns -2 without writing.

Pinned source: [stack_with_doubly_linked_list.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/stacks/stack_with_doubly_linked_list.py). See [workload](workload.json) and [oracle](../../stack_with_doubly_linked_list_oracle.py).

| Language | Port |
|---|---|
| C | ../../../c/s/stack_with_doubly_linked_list.c |
| C3 | ../../../c3/s/stack_with_doubly_linked_list.c3 |
| C++ | ../../../cpp/s/stack_with_doubly_linked_list.cpp |
| Elisa | ../../../elisa/s/stack_with_doubly_linked_list.elisa |
| Nim | ../../../nim/s/stack_with_doubly_linked_list.nim |
| Odin | ../../../odin/s/stack_with_doubly_linked_list.odin |
| Rust | ../../../rust/s/stack_with_doubly_linked_list.rs |
| V | ../../../v/s/stack_with_doubly_linked_list.v |
| Zig | ../../../zig/s/stack_with_doubly_linked_list.zig |

