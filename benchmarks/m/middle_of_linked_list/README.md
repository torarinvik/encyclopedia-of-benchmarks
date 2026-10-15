# Middle of the Linked List

This benchmark finds the middle node of a singly linked list using the fast/slow pointer method from TheAlgorithms/C LeetCode 876. It returns a node index so equal node payloads cannot make the result ambiguous.

## Portable input representation

The ABI receives a signed 64-bit successor-index array. Entry `i` is the next node index for node `i`; `-1` means null. Node `0` is the head. The array length is capped at 100,000, and every successor must be `-1` or an in-range index. Entries unreachable from node 0 are ignored after validation, matching the repository's other successor-index list benchmarks.

The function returns the zero-based index of the middle node reachable from node 0. For an even-length list it returns the second middle, matching the source. An empty input returns `-1`; an out-of-range successor or a cycle reachable from the head returns `-2`. Runtime is O(n) and auxiliary space is O(1).

## Workload

`workload.json` covers empty, singleton, odd- and even-length lists, an unreachable cycle, malformed successors, a reachable cycle, and a longer chain. The nine implementations use the `i64_array_scalar` ABI family.

## Upstream reference

- [TheAlgorithms/C LeetCode 876 at the pinned catalog revision](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/876.c)
