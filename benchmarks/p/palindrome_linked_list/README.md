# Palindrome Linked List

Determine whether the values in a singly linked list read the same forward and backward.

## Contract

- Input is the list's values in order, with 0 to 100,000 entries; each value is a digit from 0 through 9.
- Return 1 for a palindrome, 0 otherwise, and -1 for an invalid length or value. The empty sequence is defined as a palindrome.
- Input values are not modified. The ports compare symmetric positions in O(n) time and O(1) extra space.

## Reviewed source

The pinned [C LeetCode 234 source](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/234.c) finds the midpoint with slow/fast pointers, reverses the second half, then compares node values. This shared benchmark represents the linked-list sequence as a read-only value array and compares from both ends, preserving the same result and constant-space bound. LeetCode specifies 1 to 100,000 nodes with values 0 through 9 ([problem statement](https://leetcode.com/problems/palindrome-linked-list/)); empty input is an additional benchmark case.

## Workload and verification

[`workload.json`](workload.json) includes even and odd lists, the digit bounds, an empty sequence, and a 100,000-value palindrome. [`benchmarks/verify_palindrome_linked_list.py`](../../verify_palindrome_linked_list.py) compares the ports with direct reversal across exhaustive short sequences and deterministic random inputs.

Build with the shared `i64_array_scalar` ABI and record with `benchmarks/run_i64_array_scalar.py`.
