# PN counter

This benchmark runs bounded traces against three independent instances of the
pinned Java state-based PN counter. Each instance has its own local node ID and
its own positive and negative component maps.

## Contract

- ABI: `i64_array_bytes_output`.
- Input is `[node_count, id_a, id_b, id_c, operation_count, opcodes...]`.
  `node_count` is 1 through 16, each ID is in `0..node_count-1`, and there are 0
  through 64 single-word operations. The exact input length is `5 +
  operation_count`, at most 69 signed-i64 words. IDs may be equal; the three
  counters remain separate objects.
- Opcodes 0/1 increment/decrement A; 2/3 increment/decrement B; 4/5
  increment/decrement C. Opcodes 6/7/8 read the value of A/B/C. Opcodes 9
  through 14 merge the ordered pairs A<-B, A<-C, B<-A, B<-C, C<-A, C<-B.
  Opcodes 15 through 20 compare the pairs A-vs-B, A-vs-C, B-vs-A, B-vs-C,
  C-vs-A, C-vs-B.
- A value is `sum(P) - sum(N)`. Merge takes the componentwise maximum of both
  P and N. The Java comparison predicate is preserved exactly: it returns false
  if any node has both `this.P[i] > other.P[i]` and
  `this.N[i] > other.N[i]`; it returns true otherwise. This differs from a
  conventional componentwise partial order.
- Each mutation and merge emits `[opcode]`. A value or comparison emits
  `[opcode, result]`, where comparison is 0 or 1. Serialize words as
  little-endian signed 64-bit integers and return bytes written. Malformed
  inputs return `-1`; null output and insufficient capacity return `-2`
  without writing. The maximum output is 1,024 bytes.
- The operation bound keeps Java `int` components and value sums far from
  overflow. Equal node counts and valid IDs keep the source methods away from
  their exception paths.

The independent oracle is [`pncounter_oracle.py`](../../pncounter_oracle.py).
The workload includes comparisons where both components are greater at the
same node (false), only one component is greater (true), and P/N are greater
at different nodes (true). The last case uses a third replica to make the
cross-node state reachable through the source's merge operation.

## Pinned source

[TheAlgorithms/Java `PNCounter.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/crdt/PNCounter.java) at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

## Implementations

| Language | Port |
| --- | --- |
| C | [c/p/pncounter.c](../../../c/p/pncounter.c) |
| C3 | [c3/p/pncounter.c3](../../../c3/p/pncounter.c3) |
| C++ | [cpp/p/pncounter.cpp](../../../cpp/p/pncounter.cpp) |
| Elisa | [elisa/p/pncounter.elisa](../../../elisa/p/pncounter.elisa) |
| Nim | [nim/p/pncounter.nim](../../../nim/p/pncounter.nim) |
| Odin | [odin/p/pncounter.odin](../../../odin/p/pncounter.odin) |
| Rust | [rust/p/pncounter.rs](../../../rust/p/pncounter.rs) |
| V | [v/p/pncounter.v](../../../v/p/pncounter.v) |
| Zig | [zig/p/pncounter.zig](../../../zig/p/pncounter.zig) |
