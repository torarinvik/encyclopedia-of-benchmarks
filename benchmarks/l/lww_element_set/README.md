# LWW Element Set

This benchmark replays add, remove, lookup, and merge operations on two
deterministic replicas of the pinned Java last-write-wins element set.

## Contract

Input is a signed-i64 array `[operation_count, opcode, arg0, arg1, arg2, ...]`.
Each operation has four words. The operation count is 0 through 24, and the
array length must equal `1 + 4 * operation_count`.

| Opcode | Operation | Arguments |
|---:|---|---|
| `0` | Add | `replica, key, timestamp_seconds` |
| `1` | Remove | `replica, key, timestamp_seconds` |
| `2` | Lookup | `replica, key, 0` |
| `3` | Merge | `target_replica, source_replica, 0` |

Replica IDs are 0 or 1. Keys and timestamps are signed 32-bit integers.
Timestamps are deterministic logical Unix seconds mapped to Java
`Instant.ofEpochSecond`, preserving timestamp order and equality without using
the wall clock. Add and remove overwrite their respective per-key timestamp
even when the supplied timestamp is older than the previous one.

Each replica keeps independent add and remove maps. Lookup is true only when
the key has an add timestamp and either has no remove timestamp or its add
timestamp is strictly later. Merge copies entries from the source replica into
the target, resolving add and remove maps independently: keep the later
timestamp, and on equal timestamps select the incoming source entry. Merging a
replica into itself is a no-op.

The scalar result packs lookup results into a bitmask. The first lookup in the
trace is bit 0, the second is bit 1, and so on; a set bit means true. Traces
with no lookup operations return zero. Null input, malformed framing, an
unknown opcode, a nonzero reserved argument, or an out-of-domain replica, key,
or timestamp returns `-1`.

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Independent oracle: [`benchmarks/lww_element_set_oracle.py`](../../lww_element_set_oracle.py)

## ABI and language ports

The ports use the `i64_array_scalar_call` ABI and return the lookup bitmask
directly. Build and record a port with:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm lww_element_set --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/l/lww_element_set/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithm lww_element_set --languages rust
```

| Language | Source |
| --- | --- |
| C | [`c/l/lww_element_set.c`](../../../c/l/lww_element_set.c) |
| C3 | [`c3/l/lww_element_set.c3`](../../../c3/l/lww_element_set.c3) |
| C++ | [`cpp/l/lww_element_set.cpp`](../../../cpp/l/lww_element_set.cpp) |
| Elisa | [`elisa/l/lww_element_set.elisa`](../../../elisa/l/lww_element_set.elisa) |
| Nim | [`nim/l/lww_element_set.nim`](../../../nim/l/lww_element_set.nim) |
| Odin | [`odin/l/lww_element_set.odin`](../../../odin/l/lww_element_set.odin) |
| Rust | [`rust/l/lww_element_set.rs`](../../../rust/l/lww_element_set.rs) |
| V | [`v/l/lww_element_set.v`](../../../v/l/lww_element_set.v) |
| Zig | [`zig/l/lww_element_set.zig`](../../../zig/l/lww_element_set.zig) |

## Pinned source

- [TheAlgorithms/Java `LWWElementSet.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/crdt/LWWElementSet.java), commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.
