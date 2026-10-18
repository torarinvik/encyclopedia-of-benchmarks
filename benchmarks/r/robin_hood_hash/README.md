# Robin Hood hash map

This benchmark runs a bounded operation trace against the pinned Zig
`RobinHoodHashMap(u32, u32, 16)`. It covers puts, gets, removes, size and
load-factor queries, maximum probe-sequence length, clearing, and empty-state
queries. Keys and values are unsigned 32-bit integers; values are restricted so
that they do not overlap the adapter's result tags.

## Input and output

The ABI is `i64_array_bytes_output`. Input is
`[operation_count, (opcode, key, value)...]`, with exactly three words per
operation and 0–64 operations. Keys must be in `[0, 2^32-1]`. Put values are
in `[100, 1,000,000]`; non-put operations use a zero value field.

- `0`: put `(key, value)`; emits `-2`.
- `1`: get `key`; emits its value or `-1` if absent.
- `2`: remove `key`; emits `1` if found, otherwise `0`.
- `3`: length; emits the number of entries.
- `4`: load factor; emits the integer percentage `(count*100)/16`, rounded
  down as in the source.
- `5`: maximum probe sequence length (PSL), or zero when empty.
- `6`: clear; emits `-3`.
- `7`: empty-state query; emits `1` when empty and `0` otherwise.

Every operation emits one signed 64-bit result in little-endian byte order, so
the output length is `8*operation_count`, at most 512 bytes. A valid trace may
not exceed 14 live entries. This keeps the source's floor-based load-factor
check below 90% before every put. The map uses capacity 16, a power of two, so
every cluster is shorter than the source's 64-probe bound. The benchmark does
not exercise `HashMapFull` or `ProbeDistanceExceeded`, nor does it claim
unconstrained-map behavior. Invalid input returns `-1`; null output or
insufficient capacity returns `-2` without writes after input validation.

The source hashes each integer key by multiplying its unsigned value by
`0x9e3779b97f4a7c15` with 64-bit wraparound, taking the high 32 bits, then
masking by `capacity-1`. Insertion swaps an incoming entry with a resident
whose PSL is smaller. Lookup stops at an empty slot or when its search PSL is
larger than the resident PSL. Removal backshifts following entries until an
empty slot or an entry with PSL zero.

## Pinned source and fixtures

The source is TheAlgorithms/Zig
[`robin_hood_hash.zig`](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/tiger_style/robin_hood_hash.zig)
at commit `86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3`. The fixture definitions
and ABI cases are in [workload.json](workload.json). The independent map
oracle is [`benchmarks/robin_hood_hash_oracle.py`](../../robin_hood_hash_oracle.py).

## Language ports

| Language | Source |
| --- | --- |
| C | [c/r/robin_hood_hash.c](../../../c/r/robin_hood_hash.c) |
| C3 | [c3/r/robin_hood_hash.c3](../../../c3/r/robin_hood_hash.c3) |
| C++ | [cpp/r/robin_hood_hash.cpp](../../../cpp/r/robin_hood_hash.cpp) |
| Elisa | [elisa/r/robin_hood_hash.elisa](../../../elisa/r/robin_hood_hash.elisa) |
| Nim | [nim/r/robin_hood_hash.nim](../../../nim/r/robin_hood_hash.nim) |
| Odin | [odin/r/robin_hood_hash.odin](../../../odin/r/robin_hood_hash.odin) |
| Rust | [rust/r/robin_hood_hash.rs](../../../rust/r/robin_hood_hash.rs) |
| V | [v/r/robin_hood_hash.v](../../../v/r/robin_hood_hash.v) |
| Zig | [zig/r/robin_hood_hash.zig](../../../zig/r/robin_hood_hash.zig) |
