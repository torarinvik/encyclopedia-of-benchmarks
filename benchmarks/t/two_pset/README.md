# Two-Phase Set

This benchmark models the pinned Java TwoPSet with two initially empty replicas and integer elements 0 through 63. Each replica keeps an additions set and a removal tombstone set. Lookup checks additions minus tombstones. Add inserts into additions without clearing a tombstone. Remove tombstones an element only when it is currently present, so removing an absent element does not prevent a later add.

## Contract

- Input is a signed 64-bit array encoded as [q, (opcode, set_id, value, other_set_id) repeated q times]. q is 0 through 256, the exact length is 1 + 4*q, and the maximum length is 1,025.
- Opcodes 0, 1, and 2 add, remove, and look up an element. They require set_id 0 or 1, value 0 through 63, and other_set_id zero.
- Opcode 3 compares set_id against other_set_id. Both IDs are 0 or 1, value is zero, and the result is true only when the receiver's additions set and tombstone set are each subsets of the other replica's corresponding set. The comparison is directional; self-comparison is allowed.
- Opcode 4 merges set_id with other_set_id by unioning both internal sets and assigning the returned new set to set_id. Both IDs are 0 or 1 and value is zero. The other replica remains unchanged; self-merge is allowed.
- Lookup and compare return 1 for true and 0 for false. Add, remove, and merge return zero. Invalid layout, opcode, selector, dummy field, or element returns -1.
- The result is a deterministic state digest. Start with h = 0. After each operation append [opcode, result]. After all operations append four 64-element membership arrays as 0 or 1 tokens in this order: replica 0 additions, replica 0 tombstones, replica 1 additions, replica 1 tombstones; within each array, elements are ordered 0 through 63. For every token t, update h = (h * 1,000,003 + t) mod 1,000,000,007. With no operations, the digest is zero.

## Workload and implementation

[`workload.json`](workload.json) covers absent removal followed by add, add after tombstoning, directional comparison, merge with tombstones, source preservation, self-operations, element boundaries, and malformed records. All nine ports use the i64_array_scalar ABI family.

## Upstream source

- [Java TwoPSet.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/crdt/TwoPSet.java)

Build with `python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm two_pset --language c` and record with `benchmarks/run_i64_array_scalar.py`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/t/two_pset.c`](../../../c/t/two_pset.c) |
| C3 | [`c3/t/two_pset.c3`](../../../c3/t/two_pset.c3) |
| C++ | [`cpp/t/two_pset.cpp`](../../../cpp/t/two_pset.cpp) |
| Elisa | [`elisa/t/two_pset.elisa`](../../../elisa/t/two_pset.elisa) |
| Nim | [`nim/t/two_pset.nim`](../../../nim/t/two_pset.nim) |
| Odin | [`odin/t/two_pset.odin`](../../../odin/t/two_pset.odin) |
| Rust | [`rust/t/two_pset.rs`](../../../rust/t/two_pset.rs) |
| V | [`v/t/two_pset.v`](../../../v/t/two_pset.v) |
| Zig | [`zig/t/two_pset.zig`](../../../zig/t/two_pset.zig) |
