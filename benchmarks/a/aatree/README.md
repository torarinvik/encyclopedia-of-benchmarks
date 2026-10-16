# AA tree

This benchmark follows the pinned C# `AaTree<TKey>` insertion, removal, search, minimum, and maximum operations. Insertion restores AA invariants with `Skew` and `Split`; deletion lowers node levels, then rebalances with the same operations. The source stores unique keys, throws on duplicate insertion or removal of a missing key, and supports a custom comparer. The portable contract uses signed 32-bit integer keys and their natural ascending order.

Source: [AATree.cs](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/AATree/AATree.cs) and [AATreeNode.cs](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/AATree/AATreeNode.cs).

## Contract

Input is a signed-i64 array containing an operation count from 0 to 256 followed by `(opcode, key)` pairs. Opcodes are `0` insert, `1` remove, `2` contains, `3` minimum, and `4` maximum. Min/max operations require a zero key field and a nonempty tree. Duplicate inserts, missing removals, queries of min/max on an empty tree, out-of-range keys, and malformed arrays return `-1`. Insufficient output capacity returns `-2`.

The output contains one little-endian signed-i32 value per operation: current tree size after insert/remove, 0 or 1 for contains, and the selected key for min/max. The function returns the number of output bytes.

Verify the Rust implementation with `python3 benchmarks/verify_i64_array_bytes_output.py --algorithm aatree --languages rust`.
