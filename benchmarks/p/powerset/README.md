# Powerset

The pinned Haskell `powerset` returns `[[]]` for an empty list. For a nonempty list it appends the powerset of the tail, then the same subsets with the current head prepended. This yields a deterministic exclude-then-include order.

## Contract

Input is `[count, values...]`, with 0 to 6 signed 32-bit values. Output starts with the subset count as little-endian u16; each subset is encoded as a one-byte length followed by its values as little-endian signed i64s. Values may repeat, matching the list-based source semantics. The maximum output is 1,602 bytes.

See [`workload.json`](workload.json) and the runtime [oracle](../../powerset_oracle.py). Pinned source: [TheAlgorithms/Haskell `Powerset.hs`](https://github.com/TheAlgorithms/Haskell/blob/9dcabef99fb8995a760ff25a9e0d659114c0b9d3/src/Misc/Powerset.hs).

| Language | Port |
|---|---|
| C | [`c/p/powerset.c`](../../../c/p/powerset.c) |
| C3 | [`c3/p/powerset.c3`](../../../c3/p/powerset.c3) |
| C++ | [`cpp/p/powerset.cpp`](../../../cpp/p/powerset.cpp) |
| Elisa | [`elisa/p/powerset.elisa`](../../../elisa/p/powerset.elisa) |
| Nim | [`nim/p/powerset.nim`](../../../nim/p/powerset.nim) |
| Odin | [`odin/p/powerset.odin`](../../../odin/p/powerset.odin) |
| Rust | [`rust/p/powerset.rs`](../../../rust/p/powerset.rs) |
| V | [`v/p/powerset.v`](../../../v/p/powerset.v) |
| Zig | [`zig/p/powerset.zig`](../../../zig/p/powerset.zig) |
