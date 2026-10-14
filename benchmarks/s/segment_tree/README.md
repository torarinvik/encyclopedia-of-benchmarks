# Segment tree operation trace

This benchmark builds a segment tree over a bounded signed integer array, applies point assignments, and answers inclusive range queries. Each trace selects one associative aggregate: sum, minimum, or maximum. This captures the shared range-query structure in the pinned sources while giving every language the same operation contract.

## Contract

- Input is packed as `[aggregate_mode, item_count, value_0, ..., value_n-1, operation_count, opcode, first, second, ...]`.
- Aggregate mode `0` is sum, `1` is minimum, and `2` is maximum. The selected mode applies to all queries in one trace.
- Item count is from 1 through 256; operation count is from 0 through 512; values are from -1,000,000 through 1,000,000.
- Opcode `0` assigns `second` to array index `first`. Opcode `1` queries the inclusive range `[first, second]`.
- Invalid modes, dimensions, values, opcodes, indices, or ranges return `-1`.
- The scalar result is a weighted checksum of query results followed by the final array contents. Valid results are positive and fit signed 64-bit integers.
- Implementations use a power-of-two iterative segment tree, fixed-size arrays, and portable integer comparisons and arithmetic.

The shared limits keep sums within ±256,000,000. Minimum and maximum identities are outside the allowed value range, so padding leaves cannot change a valid query.

## Workload and verification

[`workload.json`](workload.json) records 28 valid and invalid traces, including all three aggregates, single-element and non-power-of-two arrays, repeated updates, negative values, the maximum array and operation counts, and malformed inputs. [`verify_segment_tree.py`](../../verify_segment_tree.py) checks 23,474 traces per language against a direct-array oracle and verifies every workload record.

## Reviewed TheAlgorithms sources

- [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/binary_trees/segment_tree.c) — generic combine function; its example tests range minimum queries.
- [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/segment_tree.cpp) — point assignments and inclusive range sums.
- [C#](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/SegmentTrees/SegmentTree.cs) — inclusive range sums.
- [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/SegmentTree.java) — point assignments and inclusive range sums.
- [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Tree/SegmentTree.js) — point assignments and range sums.
- [Lua](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/data_structures/segment_tree.lua) — caller-selected associative aggregate with point assignments.
- [PHP](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/DataStructures/SegmentTree/SegmentTree.php) — sum by default, caller-selected aggregate, and point or range assignments.
- [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/segment_tree.py) — range maximum queries and range assignments.
- [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/data_structures/segment_tree.rs) — caller-selected minimum, maximum, or sum with point assignments.

## Implementations

The nine portable ports use the shared `i64_array_scalar` ABI. Their source files are in the `s` folder for each language.
