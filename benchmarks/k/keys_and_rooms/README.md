# Keys and Rooms

Rooms contain keys that open other rooms. Starting in room zero, return whether every room can be visited. The ports use an explicit stack and mark a room when it is scheduled, so each room is pushed at most once.

## Contract

- Input is a signed 64-bit integer array: room count `n`, followed by `n` key lists, each encoded as its key count and then zero-based room indices.
- The room count is 2 through 1,000. Each key list contains at most `n` entries; every key must be in `0..n-1`. Duplicate keys are accepted and have no effect after the target room is visited.
- The packed input must contain exactly the declared key lists and be at most 100,001 values.
- Return 1 if every room is reachable from room zero, 0 otherwise, and -1 for malformed input.

## Workload and verification

[`workload.json`](workload.json) covers reachable and unreachable graphs, cycles, duplicate keys, malformed encodings, and a 1,000-room chain. [`benchmarks/verify_keys_and_rooms.py`](../../verify_keys_and_rooms.py) checks the ports against a Python traversal oracle on exhaustive small directed graphs, deterministic random graphs, dense and sparse boundaries, and every workload case.

## Reviewed source

The pinned C [LeetCode 841 implementation](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/841.c) uses depth-first search from room zero and counts the visited rooms.

## Implementations

All nine ports use the shared i64-array/scalar ABI.
