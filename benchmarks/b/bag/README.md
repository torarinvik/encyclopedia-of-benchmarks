# Bag

This benchmark follows the multiset behavior shared by the pinned C# and Java `Bag` sources. The C# version aggregates equal items into linked nodes with a multiplicity; the Java version stores one node per insertion and prepends it. Their iteration order and representations differ, so this contract compares size, emptiness, and membership.

## Contract

- Input is `[insert_count, inserted_values..., query_count, query_values...]`. Insert and query counts are limited to 128 and 64; values are signed 32-bit integers carried in a signed 64-bit ABI array.
- Output is `[size, is_empty, contains(query_0), ...]`, encoded as little-endian signed i64 values. Each membership result is 0 or 1. Java exposes `contains`; C# supports the same query by iterating its bag. Enumeration order and internal node layout are not compared.
- Invalid input returns `-1`; insufficient output capacity returns `-2` without writing; success returns the output byte count.
- Ports use a linked-list-style multiset and portable integer operations. No architecture-specific instructions are used.

The 16 published workloads cover empty and singleton bags, repeated values, signed boundaries, absent and present queries, and larger traces. The verifier also checks randomized operation sequences, malformed inputs, and output capacity.

## Build and run

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm bag --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/b/bag/rust/build.json
```

## Implementations

| Language | Source |
|---|---|
| C | [`c/b/bag.c`](../../../c/b/bag.c) |
| C3 | [`c3/b/bag.c3`](../../../c3/b/bag.c3) |
| C++ | [`cpp/b/bag.cpp`](../../../cpp/b/bag.cpp) |
| Elisa | [`elisa/b/bag.elisa`](../../../elisa/b/bag.elisa) |
| Nim | [`nim/b/bag.nim`](../../../nim/b/bag.nim) |
| Odin | [`odin/b/bag.odin`](../../../odin/b/bag.odin) |
| Rust | [`rust/b/bag.rs`](../../../rust/b/bag.rs) |
| V | [`v/b/bag.v`](../../../v/b/bag.v) |
| Zig | [`zig/b/bag.zig`](../../../zig/b/bag.zig) |

## Pinned sources

- TheAlgorithms/C-Sharp [`Bag.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/Bag/Bag.cs)
- TheAlgorithms/Java [`Bag.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/bags/Bag.java)
