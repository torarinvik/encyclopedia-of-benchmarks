# Random replacement cache

This benchmark runs a bounded, single-threaded trace through the pinned Java
`RRCache`. It observes puts, gets, sizes, and random replacement. Each put uses
a fixed positive TTL of 1,000,000,000 milliseconds. The workload has at most 32
operations, so it does not reach the default periodic expired-entry sweep at
100 accesses. Expiration timing and concurrent scheduling are outside the
contract.

## Input and output

The ABI is `i64_array_bytes_output`. Input is
`[capacity, seed, operation_count, (opcode, key, value)...]`, with a fixed
three-word record for each operation. Capacity is 1–8, seed is any signed
64-bit integer, and operation count is 0–32. The input length must equal
`3 + 3*operation_count`.

- Opcode `0` performs `put(key, value)`. Keys are 1–1024 and values are
  100–1,000,000. Its result tag is `-2`.
- Opcode `1` performs `get(key)`, with a key in 1–1024 and a zero value field.
  It emits the stored value or `-1` on a miss.
- Opcode `2` performs `size()`, with zero key and value fields. It emits the
  number of entries.

Every operation emits one signed 64-bit result, encoded as an eight-byte
little-endian integer. Stored values, miss/put tags, and size results have
disjoint ranges. A valid trace therefore emits `8*operation_count` bytes, at
most 256 bytes; an empty trace emits no bytes. Invalid input returns `-1`.
A null output or capacity below the required byte count returns `-2` without
writes, after input validation.

The cache starts empty. Updating an existing key changes its value and expiry
in place, without moving the key in insertion order or drawing randomness. A
new-key put appends the key; if the cache is full, it first draws an index and
removes that key from insertion order. Gets and sizes do not draw randomness.
The adapter supplies `new Random(seed)` semantics: the initial 48-bit state is
`(seed XOR 0x5DEECE66D) & ((1<<48)-1)`, followed by Java's specified
48-bit linear-congruential state updates and `nextInt(bound)` rejection
sampling. The Java API specifies this algorithm for portability in its
[`Random` documentation](https://docs.oracle.com/en/java/javase/26/docs/api/java.base/java/util/Random.html).

## Pinned source and fixtures

The source is TheAlgorithms/Java
[`RRCache.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/caches/RRCache.java)
at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`. Its entries expire when
`currentTimeMillis()` is strictly greater than the stored expiry. The workload
chooses a long fixed TTL so that this wall-clock behavior does not affect the
bounded trace.

The fixture definitions and ABI cases are in [workload.json](workload.json).
The independent trace and Java `Random` oracle is
[`benchmarks/rrcache_oracle.py`](../../rrcache_oracle.py).

## Language ports

| Language | Source |
| --- | --- |
| C | [c/r/rrcache.c](../../../c/r/rrcache.c) |
| C3 | [c3/r/rrcache.c3](../../../c3/r/rrcache.c3) |
| C++ | [cpp/r/rrcache.cpp](../../../cpp/r/rrcache.cpp) |
| Elisa | [elisa/r/rrcache.elisa](../../../elisa/r/rrcache.elisa) |
| Nim | [nim/r/rrcache.nim](../../../nim/r/rrcache.nim) |
| Odin | [odin/r/rrcache.odin](../../../odin/r/rrcache.odin) |
| Rust | [rust/r/rrcache.rs](../../../rust/r/rrcache.rs) |
| V | [v/r/rrcache.v](../../../v/r/rrcache.v) |
| Zig | [zig/r/rrcache.zig](../../../zig/r/rrcache.zig) |
