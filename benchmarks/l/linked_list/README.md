# Linked list operation trace

The pinned inventory contains nine `linked_list` sources and nine `singly_linked_list` sources. They include singly linked lists with head/tail insertion, search, removal, reversal, and indexed access; the generic-name candidates also include doubly linked implementations and a TypeScript interface. The benchmark defines one bounded sequence-operation contract and uses a singly linked representation in every target language. The `singly_linked_list` filename candidate aliases this contract because it provides the same common list operations.

## Contract

The `i64_array_scalar` function accepts zero to 1,024 signed 64-bit values encoded as `[opcode, payload]` pairs, for up to 512 operations. Opcodes are:

- `0`: append a value from -1,000,000 through 1,000,000
- `1`: prepend a value in the same range
- `2`: remove and return the first value, with payload zero
- `3`: remove and return the last value, with payload zero
- `4`: remove the first matching value; the observed result is `1` when found and `0` otherwise
- `5`: report whether a value is present, returning `1` or `0`
- `6`: report the list length, with payload zero

The list capacity is 256. Odd-length input, an unknown operation, an out-of-range value, a nonzero payload for operations 2, 3, or 6, a pop from an empty list, overflow, or input longer than 1,024 values returns `-1`. Empty input is valid. Nodes store a value and an integer index for the next node. A free list reuses nodes after removal. Removing the tail walks the forward links to find its predecessor, as required by the singly linked representation.

Each observed result from pop, remove, contains, or length contributes `(operation_index + 1) * (observed_value + 1,000,000)` to the checksum. The remaining values are then included from head to tail with one-based weights. Valid checksums are nonnegative and fit in signed 64-bit.

[`workload.json`](workload.json) contains 21 cases, including duplicate removal, both ends, empty-list errors, maximum capacity, and node reuse. The independent verifier checks 4,902 traces per implementation: every operation sequence through length three over representative payloads, seeded randomized valid and malformed traces, capacity boundaries, and all workload records.

## Implementations

The nine portable implementations are in [`c/l/linked_list.c`](../../../c/l/linked_list.c), [`c3/l/linked_list.c3`](../../../c3/l/linked_list.c3), [`cpp/l/linked_list.cpp`](../../../cpp/l/linked_list.cpp), [`elisa/l/linked_list.elisa`](../../../elisa/l/linked_list.elisa), [`nim/l/linked_list.nim`](../../../nim/l/linked_list.nim), [`odin/l/linked_list.odin`](../../../odin/l/linked_list.odin), [`rust/l/linked_list.rs`](../../../rust/l/linked_list.rs), [`v/l/linked_list.v`](../../../v/l/linked_list.v), and [`zig/l/linked_list.zig`](../../../zig/l/linked_list.zig). They use generic compiler targets and no architecture-specific instructions.

Run `python3 benchmarks/verify_linked_list.py --elisa-compiler PATH/TO/elisac` to check all nine implementations against the independent list oracle and validate workload records.

## Upstream references

The pinned sources were inspected for their list operations and API differences. The canonical `linked_list` candidate refers to [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/linked_list.cpp), [additional C++](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/data_structures/linked_list.cpp), [Clojure](https://github.com/TheAlgorithms/Clojure/blob/a9c5bec14928cb22fd4d69e951edf5bd15e16a18/src/data_structures/lists/linked_list.clj), [Dart](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/data_structures/linked_list/linked_list.dart), [Julia](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/data_structures/linked_list.jl), [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/data_structures/linked_list.rs), [Swift](https://github.com/TheAlgorithms/Swift/blob/2c9eb8b85dee6db46cb33452c0b904eb7d7d179c/data_structures/Linked%20List/LinkedList.swift), [TypeScript](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/data_structures/list/linked_list.ts), and [Zig](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/dataStructures/linkedList.zig).

The `singly_linked_list` alias covers [C#](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/LinkedList/SinglyLinkedList/SinglyLinkedList.cs), [Elixir](https://github.com/TheAlgorithms/Elixir/blob/6212e7e905ec2d2687e7f6e9e4b07b7fabb40f19/lib/data_structures/singly_linked_list.ex), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/lists/SinglyLinkedList.java), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Linked-List/SinglyLinkedList.js), [PHP](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/DataStructures/SinglyLinkedList.php), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/linked_list/singly_linked_list.py), [R](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/linked_list_algorithms/singly_linked_list.r), [Ruby](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/linked_lists/singly_linked_list.rb), and [TypeScript](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/data_structures/list/singly_linked_list.ts).
