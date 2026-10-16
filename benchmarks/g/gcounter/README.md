# G-Counter

This benchmark models the state-based grow-only counter from the pinned Java source `GCounter.java` (TheAlgorithms/Java, commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`). Each replica owns one component. Increment changes only that replica's component, value sums a replica's components, comparison checks componentwise `a <= b`, and merge updates `a` by componentwise maximum with `b`.

## Input contract

The input is an i64 array:

`[replica_count, operation_count, (opcode, replica_a, replica_b)*]`

There are 1–8 replicas and 0–128 operations. Opcodes are `0` increment `a` (`b` must be zero), `1` query the total of `a` (`b` must be zero), `2` compare whether `a <= b` componentwise, and `3` merge `b` into `a`. Replica indices must be in range; a component may not exceed 1,000,000 increments. Empty operation traces are valid. Malformed shape, opcode, index, argument, or counter bound returns `-1`.

The result is the signed interpretation of FNV-1a-64, starting at the standard offset basis. Hash each query result in operation order as an eight-byte little-endian signed integer, using 0/1 for comparison results; then hash the final replica-by-component matrix in row-major order. This exposes both query behavior and final state using the scalar ABI.

Run `python3 benchmarks/verify_gcounter.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1` to validate all nine ports.
