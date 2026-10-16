# Stack with a singly linked list

This package ports TheAlgorithms/Python's `LinkedStack` behavior. Push links a new node at the head; pop and peek read the head; clear drops the head; len traverses the linked nodes.

## Contract

The input is `[op_count, opcode, (value for push), ...]`. There are at most 64 operations, push values are signed 32-bit integers, and the packed stream must end exactly after the final operation. Opcode 1 pushes a value; 2 pops; 3 peeks; 4 clears; 5 returns the length. Push and clear return None. An empty pop or peek emits a terminal IndexError record and ignores later operations.

The output contains one 24-byte record per executed operation: opcode, result tag, and value as signed i64 little-endian words. Tags are 0 for integer, 2 for None, and 4 for a terminal source exception; IndexError is value 2. Maximum output is 1,536 bytes. Invalid input returns -1; null output or insufficient capacity returns -2 without writing.

Pinned source: [stack_with_singly_linked_list.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/stacks/stack_with_singly_linked_list.py). See [workload](workload.json) and [oracle](../../stack_with_singly_linked_list_oracle.py).

| Language | Port |
|---|---|
| C | ../../../c/s/stack_with_singly_linked_list.c |
| C3 | ../../../c3/s/stack_with_singly_linked_list.c3 |
| C++ | ../../../cpp/s/stack_with_singly_linked_list.cpp |
| Elisa | ../../../elisa/s/stack_with_singly_linked_list.elisa |
| Nim | ../../../nim/s/stack_with_singly_linked_list.nim |
| Odin | ../../../odin/s/stack_with_singly_linked_list.odin |
| Rust | ../../../rust/s/stack_with_singly_linked_list.rs |
| V | ../../../v/s/stack_with_singly_linked_list.v |
| Zig | ../../../zig/s/stack_with_singly_linked_list.zig |

