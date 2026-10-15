# SDBM Hash

This package ports the pinned C `sdbm` function. For each non-NUL ASCII byte it updates a 64-bit unsigned hash with `byte + (hash << 6) + (hash << 16) - hash`, preserving the source's unsigned wraparound.

## Contract

- The `i64_array_scalar` input contains 1 to 64 byte values, one per element; no NUL terminator is included.
- Accept at most 64 bytes, each in `[1, 127]`. This excludes the C source's NUL terminator from the measured payload.
- Return the 64-bit hash bit pattern interpreted as a signed i64. Invalid length or byte values return `-1`.

[`workload.json`](workload.json) includes the four pinned C examples, boundary bytes, and invalid input cases. The source's `uint64_t` result is converted to signed i64 without changing its bits.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/h/hash_sdbm.c`](../../../c/h/hash_sdbm.c) |
| C3 | [`c3/h/hash_sdbm.c3`](../../../c3/h/hash_sdbm.c3) |
| C++ | [`cpp/h/hash_sdbm.cpp`](../../../cpp/h/hash_sdbm.cpp) |
| Elisa | [`elisa/h/hash_sdbm.elisa`](../../../elisa/h/hash_sdbm.elisa) |
| Nim | [`nim/h/hash_sdbm.nim`](../../../nim/h/hash_sdbm.nim) |
| Odin | [`odin/h/hash_sdbm.odin`](../../../odin/h/hash_sdbm.odin) |
| Rust | [`rust/h/hash_sdbm.rs`](../../../rust/h/hash_sdbm.rs) |
| V | [`v/h/hash_sdbm.v`](../../../v/h/hash_sdbm.v) |
| Zig | [`zig/h/hash_sdbm.zig`](../../../zig/h/hash_sdbm.zig) |

## Upstream source

- [TheAlgorithms/C `hash_sdbm.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/hash/hash_sdbm.c)
