# Grow-only set

This benchmark models the pinned Java GSet CRDT with two replicas. Each set supports idempotent insertion and lookup; comparisons ask whether one replica is a subset of the other, and merge unions the other replica into the receiver. Elements cannot be removed.

## Contract

- Input is [operation_count, opcode, argument, ...], with at most 12 operations and element IDs in 0..15.
- Opcodes: 0 add to A, 1 add to B, 2 lookup A, 3 lookup B, 4 test A subset B, 5 test B subset A, 6 merge B into A, 7 merge A into B. Comparison and merge arguments must be zero.
- Query results are packed in execution order into bits 0..11. The final A and B membership masks occupy bits 12..27 and 28..43; query count occupies bits 44..47.
- Invalid input returns -1.

The benchmark fixes elements to small integer IDs and reports final membership masks so the replica state is deterministic across languages. It preserves the Java source's subset direction and mutating merge direction.

## Pinned source

- TheAlgorithms/Java GSet.java: https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/crdt/GSet.java
