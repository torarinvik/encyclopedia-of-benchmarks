# Set algebra

This package maps the pinned Go set implementation to integer keys. The Go implementation stores keys in a map, so its `GetItems` order is unspecified. The benchmark sorts all set-valued outputs to make the result deterministic. The pinned TypeScript file only declares a `Set<K>` interface; it has no implementation body to map.

Pinned sources:

- Go: [TheAlgorithms/Go `set.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/structure/set/set.go)
- TypeScript: [TheAlgorithms/TypeScript `set.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/data_structures/set/set.ts)

## Contract

Input is a signed 64-bit array `[operation, left_count, right_count, membership_key, left_values..., right_values...]`. Each input set can contain 0 through 64 keys. Keys and the membership key are restricted to -1,000,000 through 1,000,000. Duplicate input values are accepted and collapsed, matching insertion into the source set. Both sets are present, including when empty.

Operation codes are:

| Code | Result |
| --- | --- |
| 0 | Whether the membership key is in the left set |
| 1 | Whether the left set is a subset of the right set |
| 2 | Whether the left set is a proper subset of the right set |
| 3 | Whether the left set is a superset of the right set |
| 4 | Whether the left set is a proper superset of the right set |
| 5 | Union |
| 6 | Intersection |
| 7 | Left set minus right set |
| 8 | Symmetric difference |

Operations 0 through 4 return one little-endian signed 64-bit value, 0 or 1. Set operations return their sorted unique elements as little-endian signed 64-bit values, with no count prefix. An empty result returns 0 bytes. The function returns the output byte count, `-1` for malformed or out-of-range input, and `-2` for an undersized or null output buffer when the result is nonempty.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/set_algebra.c`](../../../c/s/set_algebra.c) |
| C3 | [`c3/s/set_algebra.c3`](../../../c3/s/set_algebra.c3) |
| C++ | [`cpp/s/set_algebra.cpp`](../../../cpp/s/set_algebra.cpp) |
| Elisa | [`elisa/s/set_algebra.elisa`](../../../elisa/s/set_algebra.elisa) |
| Nim | [`nim/s/set_algebra.nim`](../../../nim/s/set_algebra.nim) |
| Odin | [`odin/s/set_algebra.odin`](../../../odin/s/set_algebra.odin) |
| Rust | [`rust/s/set_algebra.rs`](../../../rust/s/set_algebra.rs) |
| V | [`v/s/set_algebra.v`](../../../v/s/set_algebra.v) |
| Zig | [`zig/s/set_algebra.zig`](../../../zig/s/set_algebra.zig) |
