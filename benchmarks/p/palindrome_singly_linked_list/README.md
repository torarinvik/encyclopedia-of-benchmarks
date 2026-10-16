# Palindrome singly linked list

## Contract

Input is `[node_count, signed 32-bit node values...]`, with 0–64 nodes. Return `1` when the values in forward order equal the values in reverse order, otherwise `0`. Invalid counts, malformed arrays, or values outside signed 32-bit range return `-1`.

The benchmark targets the pinned Java `isPalindromeOptimised(Node head)` method. It uses slow/fast pointers to find the middle, reverses the suffix beginning at the middle in place, and compares node values from the head and reversed suffix. The input array represents the linked list's traversal sequence; indexing implements the same midpoint and reverse-suffix comparison with constant auxiliary storage.

## Source review

The pinned Java file contains two variants. `isPalindrome(Iterable)` pushes every element onto a stack and compares by object identity (`!=`), while `isPalindromeOptimised` uses integer-valued nodes, reverses the second half, and compares `int` values. The benchmark represents the optimized integer-node method; it does not adopt the generic method's object-identity semantics.

Pinned source: [Java `PalindromeSinglyLinkedList.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/lists/PalindromeSinglyLinkedList.java).

## Workload and implementations

[`workload.json`](workload.json) covers empty, singleton, even and odd palindromes, a mismatch, negative values, repeated values, and invalid inputs. The [runtime oracle](../../palindrome_singly_linked_list_oracle.py) follows the bounded integer-node contract.

| Language | Port |
|---|---|
| C | [`c/p/palindrome_singly_linked_list.c`](../../../c/p/palindrome_singly_linked_list.c) |
| C3 | [`c3/p/palindrome_singly_linked_list.c3`](../../../c3/p/palindrome_singly_linked_list.c3) |
| C++ | [`cpp/p/palindrome_singly_linked_list.cpp`](../../../cpp/p/palindrome_singly_linked_list.cpp) |
| Elisa | [`elisa/p/palindrome_singly_linked_list.elisa`](../../../elisa/p/palindrome_singly_linked_list.elisa) |
| Nim | [`nim/p/palindrome_singly_linked_list.nim`](../../../nim/p/palindrome_singly_linked_list.nim) |
| Odin | [`odin/p/palindrome_singly_linked_list.odin`](../../../odin/p/palindrome_singly_linked_list.odin) |
| Rust | [`rust/p/palindrome_singly_linked_list.rs`](../../../rust/p/palindrome_singly_linked_list.rs) |
| V | [`v/p/palindrome_singly_linked_list.v`](../../../v/p/palindrome_singly_linked_list.v) |
| Zig | [`zig/p/palindrome_singly_linked_list.zig`](../../../zig/p/palindrome_singly_linked_list.zig) |
