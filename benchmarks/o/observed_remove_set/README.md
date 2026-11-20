# Observed-remove set

This benchmark replays a bounded operation trace against two observed-remove
set replicas. Add operations create deterministic unique tags. A removal
tombstones only the tags that its replica has already observed, so a concurrent
addition with a fresh tag survives a later merge: the set has add-wins
semantics. Merging unions both replicas' observed-add and removed-tag sets and
does not mutate the source replica.

## Contract

The `i64_array_scalar` entry point is `observed_remove_set`. Input is
`[q, (opcode, replica, element_or_zero, peer_replica)*q]`, with `0 <= q <= 32`,
replica IDs in `0..=1`, and element IDs in `0..=15`. The exact input length is
`1 + 4*q`, at most 129 signed 64-bit words.

| Opcode | Operation | Arguments |
|---:|---|---|
| 0 | Add a fresh tag for an element | `replica, element, 0` |
| 1 | Remove observed live tags for an element | `replica, element, 0` |
| 2 | Query membership | `replica, element, 0` |
| 3 | Merge peer into replica | `replica, 0, peer_replica` |
| 4 | Compare replica state as a subset of peer | `replica, 0, peer_replica` |

Each add tag is the value `(element, creator_replica,
creator_local_add_sequence)`, with the local sequence starting at zero for
each replica. Each
replica stores observed tags and tombstones separately. A membership query is
true when at least one tag for that element is observed and not tombstoned.
State comparison is componentwise subset on observed tags and tombstones.
Contains and compare results are packed into bits in trace order; mutation
operations do not consume result bits. Invalid framing, opcodes, IDs, dummy
fields, or elements return `-1`. With no reads, the result is zero.

There can be at most 32 adds and 64 unique tags, so each operation scans at most
64 entries and uses `O(64)` fixed storage for this bounded profile. This is distinct from
[`grow_only_set`](../g/grow_only_set/README.md), which has no removal semantics,
[`lww_element_set`](../l/lww_element_set/README.md), which resolves changes by
timestamps, and [`two_pset`](../t/two_pset/README.md), whose tombstones
permanently prevent re-addition of an element. OR-Set removal is tag-specific;
a later or concurrent fresh tag can keep the element present.

The primary reference uses compact numeric tag IDs and fixed arrays. The
independent reference uses tuple tags and Python sets. The workload exercises
concurrent add-wins merges, remove-after-observation, re-addition, multi-tag
removal, directional comparison, source preservation, maximum-size traces,
invalid frames, and empty traces. No
reference, port, or fixture has been executed.

## Source and rights

Algorithm source: [TheAlgorithms/Java `ORSet.java`](https://github.com/TheAlgorithms/Java/blob/master/src/main/java/com/thealgorithms/datastructures/crdt/ORSet.java).
The source repository is MIT-licensed; only the algorithm idea was used. The
benchmark does not copy the Java implementation: its `Pair` class uses object
identity equality, which prevents independently created equal tag pairs from
matching in tombstone sets. This clean-room profile uses value-based
`(element, replica, sequence)` tags and deterministic sequence numbers instead
of UUIDs. See
[`RIGHTS.md`](RIGHTS.md).

## Implementations

| Language | Source |
|---|---|
| C | [`c/o/observed_remove_set.c`](../../../c/o/observed_remove_set.c) |
| C3 | [`c3/o/observed_remove_set.c3`](../../../c3/o/observed_remove_set.c3) |
| C++ | [`cpp/o/observed_remove_set.cpp`](../../../cpp/o/observed_remove_set.cpp) |
| Elisa | [`elisa/o/observed_remove_set.elisa`](../../../elisa/o/observed_remove_set.elisa) |
| Mojo | [`mojo/o/observed_remove_set.mojo`](../../../mojo/o/observed_remove_set.mojo) |
| Nim | [`nim/o/observed_remove_set.nim`](../../../nim/o/observed_remove_set.nim) |
| Odin | [`odin/o/observed_remove_set.odin`](../../../odin/o/observed_remove_set.odin) |
| Rust | [`rust/o/observed_remove_set.rs`](../../../rust/o/observed_remove_set.rs) |
| V | [`v/o/observed_remove_set.v`](../../../v/o/observed_remove_set.v) |
| Zig | [`zig/o/observed_remove_set.zig`](../../../zig/o/observed_remove_set.zig) |

The package-local [`verify_workload.py`](verify_workload.py) statically checks
fixture metadata and port inventory. The shared scalar suite registration is
handled separately.
