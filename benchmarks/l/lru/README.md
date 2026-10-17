# Least-recently-used cache

This benchmark follows the LRU cache in the pinned
[TheAlgorithms/Go implementation](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/cache/lru.go)
and its [doubly linked list](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/structure/linkedlist/doubly.go).
The cache stores values by key, refreshes a key's recency on `Get`, and evicts
the least recently used entry when a new key is put into a full cache.

## Contract

- ABI: `i64_array_bytes_output`. Input is
  `[capacity, operation_count, (opcode, key, value)*]`, exactly three signed-i64
  cells per operation. Capacity is 2..16 and operation count is 0..32. Keys and
  values are in `[-1_000_000, 1_000_000]`; integer keys are represented as
  canonical decimal strings when adapting to the Go source.
- Opcode `0` is `Put(key, value)` and requires a key not used by any earlier
  put in the trace. Opcode `1` is `Get(key)` and requires the key to be
  currently present; its unused `value` argument must be zero. A get hit
  refreshes the key to most-recently-used. A put into a full cache evicts its
  least-recently-used entry. These constraints keep traces within the source's
  safe common domain.
- Each operation emits little-endian signed-i64 fields
  `[opcode, return_count, values...]`. A put emits zero values; a get emits its
  cached value. The final instrumentation record is
  `[2, cache_length, (key, value)...]`, with entries ordered from
  least-recently-used to most-recently-used.
- Invalid input framing, operation codes, ranges, repeated put keys, or gets
  for absent keys return `-1`. The complete trace is validated before output
  checks. A null output pointer or insufficient capacity returns `-2` without
  writing. Success returns the byte count.
- The maximum valid input contains 98 i64 values; 99 values are accepted for
  malformed trailing-field checks. The maximum output is 114 i64 fields, or
  912 bytes, reached with capacity 16, 16 distinct puts, then 16 gets.
- The benchmark intentionally restricts capacity to 2..16, matching the
  catalog's selected safe common domain. The source also handles capacity 1;
  capacity 0 is excluded because a put can attempt to evict from an empty list.

The independent oracle is [`benchmarks/lru_oracle.py`](../../lru_oracle.py),
and [`workload.json`](workload.json) covers recency refresh, eviction, invalid
traces, input boundaries, and output-buffer handling.

## Language ports

| Language | Port |
| --- | --- |
| C | [`c/l/lru.c`](../../../c/l/lru.c) |
| C3 | [`c3/l/lru.c3`](../../../c3/l/lru.c3) |
| C++ | [`cpp/l/lru.cpp`](../../../cpp/l/lru.cpp) |
| Elisa | [`elisa/l/lru.elisa`](../../../elisa/l/lru.elisa) |
| Nim | [`nim/l/lru.nim`](../../../nim/l/lru.nim) |
| Odin | [`odin/l/lru.odin`](../../../odin/l/lru.odin) |
| Rust | [`rust/l/lru.rs`](../../../rust/l/lru.rs) |
| V | [`v/l/lru.v`](../../../v/l/lru.v) |
| Zig | [`zig/l/lru.zig`](../../../zig/l/lru.zig) |
