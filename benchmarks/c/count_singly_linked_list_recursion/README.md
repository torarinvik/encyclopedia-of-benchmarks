# Count Singly Linked List Recursively

Count the nodes in a finite singly linked list using the source’s recursive rule: an empty tail contributes zero, and each node contributes one plus the count of its successor.

## Source

This package follows the pinned [TheAlgorithms/Java `CountSinglyLinkedListRecursion`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/lists/CountSinglyLinkedListRecursion.java). Its helper returns zero at a null head and otherwise recurses on `head.next`, adding one for the current node.

## Contract

- ABI: `i64_array_scalar`, with packed input `[node_count, node_payloads...]`.
- Payload order represents the nodes from head to tail; the next link is the following array element and the null link after the last payload is implicit.
- `node_count` is in `0..=64`, and the input contains exactly `node_count + 1` values. Each payload is a signed 32-bit integer, matching the Java node type; payload values in this range do not affect the count.
- Return the number of nodes. Invalid counts or packed lengths return `-1`.
- Each port recursively advances through the packed nodes. The 64-node limit bounds recursive depth consistently across languages.

## Workload and oracle

[`workload.json`](workload.json) covers an empty list, single and longer chains, signed payload boundaries, maximum recursive depth, and malformed packed inputs. The independent oracle validates the encoding and returns the represented node count. Nine ports export `count_singly_linked_list_recursion` for the shared `i64_array_scalar` runner.

Verify the nine ports against the independent oracle with `python3 benchmarks/verify_i64_array_scalar.py --algorithms count_singly_linked_list_recursion`.
