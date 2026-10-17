# Range-multiply segment-tree trace

This benchmark follows the pinned C# `SegmentTreeApply` and its base
`SegmentTree`. It builds a sum tree over an integer array, applies inclusive
range multiplications, answers inclusive range-sum queries, and returns a
weighted checksum of query results.

## Contract

The `i64_array_scalar` input is
`[array_length, initial_values..., operation_count, (opcode, left, right, argument) * operation_count]`.
The array has 1 through 64 elements; each initial element is -1, 0, or 1. There
are at most 20 operations.

Each operation contains four integers:

- `0, left, right, multiplier`: call `Apply(left, right, multiplier)`, which
  multiplies every element in the inclusive range by `multiplier`
- `1, left, right, 0`: call `Query(left, right)` and observe the inclusive
  range sum; the final zero is reserved and required

Both range endpoints must satisfy `0 <= left <= right < array_length`.
Multipliers are -2 through 2. Unknown opcodes, invalid ranges, invalid initial
values or multipliers, a nonzero query reserved field, truncated records, and
trailing values return `-1`.

For a query result `r` at zero-based operation position `i`, the checksum adds
`(i + 1) * (r + 67,108,865)`. Range updates do not contribute a result, but
still affect later operation positions. With at most 20 multiplications of
magnitude 2, every element and lazy multiplier product has magnitude at most
2^20. The largest possible absolute range sum is 64 * 2^20 = 67,108,864, so
all source `int` arithmetic remains in range and valid checksums are positive.
The maximum valid frame contains 146 integers; the maximum parseable frame
contains 147.

The source pads its internal tree to the next power of two; valid ranges address
only the original array. A full-range update stores a pending multiplier at a
tree node. Partial queries multiply child results by each pending ancestor
operand, and partial updates recompute the parent from its operand and child
sums. The workload includes non-power-of-two lengths, overlapping updates,
zeroing, sign changes, and compounded factors.

## Pinned sources

- TheAlgorithms/C-Sharp [`SegmentTreeApply.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/SegmentTrees/SegmentTreeApply.cs), commit `96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c`
- Its base class, [`SegmentTree.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/SegmentTrees/SegmentTree.cs), same commit

## Workload

The workload is [`workload.json`](workload.json); the independent array
oracle is [`benchmarks/segment_tree_apply_oracle.py`](../../segment_tree_apply_oracle.py).
