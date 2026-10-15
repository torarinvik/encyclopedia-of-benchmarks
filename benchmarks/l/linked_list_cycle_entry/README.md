# Linked List Cycle Entry

This benchmark implements Floyd's tortoise and hare algorithm to locate the first node in the cycle of a singly linked list. It is based on TheAlgorithms/C LeetCode 142 implementation.

## Portable input representation

The ABI accepts an array of signed 64-bit successor indices. Entry `i` gives the index of node `i`'s next node; `-1` means null. Node `0` is the head, and entries for nodes not reachable from node `0` do not affect the result. This representation avoids allocator and pointer-layout differences across languages.

Valid inputs contain at most 100,000 nodes and every successor is `-1` or an index in the array. The function returns the zero-based index where the reachable cycle begins, `-1` for an acyclic list, and `-2` for malformed input.

## Workload

`workload.json` covers empty and singleton lists, linear and cyclic lists, a cycle after a prefix, an unreachable cycle, and invalid indices. The independent verifier exhaustively checks all successor arrays through five nodes and includes seeded random and maximum-length cases.

The timed operation includes input validation and cycle-entry search. All ports use the same C ABI and have no target-specific instructions or CPU-specific build flags.
