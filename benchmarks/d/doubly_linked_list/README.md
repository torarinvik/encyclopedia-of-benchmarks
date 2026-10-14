# Doubly linked list operation trace

The pinned inventory finds doubly linked list implementations in 14 TheAlgorithms repositories. They expose different operations: examples include positional insertion and deletion, head/tail insertion, removal by value, search, reversal, and size queries. This benchmark normalizes the shared end-insertion/removal and value-removal behavior into one operation trace; its storage uses portable integer indices into a fixed node pool.

## Contract

The `i64_array_scalar` function accepts zero to 1,024 signed 64-bit values encoded as `[opcode, payload]` pairs, for up to 512 operations. Opcodes are:

- `0`: append a value from -1,000,000 through 1,000,000
- `1`: prepend a value in the same range
- `2`: remove and return the first value, with payload zero
- `3`: remove and return the last value, with payload zero
- `4`: remove the first matching value; the observed result is `1` when found and `0` otherwise
- `5`: report whether a value is present, returning `1` or `0`
- `6`: report the list length, with payload zero

The list capacity is 256. Odd-length input, an unknown operation, an out-of-range value, a nonzero payload for operations 2, 3, or 6, a pop from an empty list, overflow, or input longer than 1,024 values returns `-1`. Empty input is valid. The fixed pool stores values and integer next/previous links; freed nodes are reused through a free list.

Each observed result from pop, remove, contains, or length contributes `(operation_index + 1) * (observed_value + 1,000,000)` to the checksum. The remaining values are then included in forward and reverse order with one-based weights. The verifier checks both link directions through that checksum. Valid checksums are nonnegative and fit in signed 64-bit.

[`workload.json`](workload.json) contains 21 cases, including duplicate removal, both ends, empty-list errors, maximum capacity, and node reuse. The independent verifier checks 4,902 traces per implementation: every operation sequence through length three over representative payloads, seeded randomized valid and malformed traces, capacity boundaries, and all workload records.

## Implementations

The nine portable implementations are in [`c/d/doubly_linked_list.c`](../../../c/d/doubly_linked_list.c), [`c3/d/doubly_linked_list.c3`](../../../c3/d/doubly_linked_list.c3), [`cpp/d/doubly_linked_list.cpp`](../../../cpp/d/doubly_linked_list.cpp), [`elisa/d/doubly_linked_list.elisa`](../../../elisa/d/doubly_linked_list.elisa), [`nim/d/doubly_linked_list.nim`](../../../nim/d/doubly_linked_list.nim), [`odin/d/doubly_linked_list.odin`](../../../odin/d/doubly_linked_list.odin), [`rust/d/doubly_linked_list.rs`](../../../rust/d/doubly_linked_list.rs), [`v/d/doubly_linked_list.v`](../../../v/d/doubly_linked_list.v), and [`zig/d/doubly_linked_list.zig`](../../../zig/d/doubly_linked_list.zig). They use generic compiler targets and no architecture-specific instructions.

Run `python3 benchmarks/verify_doubly_linked_list.py --elisa-compiler PATH/TO/elisac` to check all nine implementations against the independent list oracle and validate workload records.

## Upstream references

The pinned sources were reviewed for their list operations; their APIs differ, so this benchmark provides a common contract while retaining attribution to every discovered repository source.

- [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/linked_list/doubly_linked_list.c)
- [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/doubly_linked_list.cpp)
- [C++ additional repository](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/data_structures/doubly_linked_list.cpp)
- [C#](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/LinkedList/DoublyLinkedList/DoublyLinkedList.cs)
- [Elixir](https://github.com/TheAlgorithms/Elixir/blob/6212e7e905ec2d2687e7f6e9e4b07b7fabb40f19/lib/data_structures/doubly_linked_list.ex)
- [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/lists/DoublyLinkedList.java)
- [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Linked-List/DoublyLinkedList.js)
- [PHP](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/DataStructures/DoublyLinkedList.php)
- [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/linked_list/doubly_linked_list.py)
- [R](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/linked_list_algorithms/doubly_linked_list.r)
- [Ruby](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/linked_lists/doubly_linked_list.rb)
- [Swift](https://github.com/TheAlgorithms/Swift/blob/2c9eb8b85dee6db46cb33452c0b904eb7d7d179c/data_structures/doubly_linked_list/DoublyLinkedList.swift)
- [TypeScript](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/data_structures/list/doubly_linked_list.ts)
- [Zig](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/dataStructures/doublyLinkedList.zig)
