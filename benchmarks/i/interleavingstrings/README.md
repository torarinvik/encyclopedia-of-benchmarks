# Interleaving strings

The pinned Go `IsInterleave` uses dynamic programming to decide whether a target string can be formed by interleaving two source strings while preserving the order of each source. The benchmark keeps that recurrence on bounded ASCII byte strings.

## Contract

The `i64_array_scalar` ABI accepts `[first_length, second_length, target_length, first_bytes..., second_bytes..., target_bytes...]`. Each source is 0–32 bytes, and target length must be their sum. Bytes are ASCII 0–127. Return `1` when the target is a valid interleaving and `0` otherwise; malformed bounds, lengths, or bytes return `-1`. The DP recurrence runs in O(mn) time and uses O(mn) space.

[`workload.json`](workload.json) includes both pinned examples, repeated-symbol ambiguity, empty sources, a mismatch, invalid length/byte cases, and maximum source lengths.

## Pinned source

- [Go `interleavingstrings.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/dynamic/interleavingstrings.go)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/i/interleavingstrings.c`](../../../c/i/interleavingstrings.c) |
| C3 | [`c3/i/interleavingstrings.c3`](../../../c3/i/interleavingstrings.c3) |
| C++ | [`cpp/i/interleavingstrings.cpp`](../../../cpp/i/interleavingstrings.cpp) |
| Elisa | [`elisa/i/interleavingstrings.elisa`](../../../elisa/i/interleavingstrings.elisa) |
| Nim | [`nim/i/interleavingstrings.nim`](../../../nim/i/interleavingstrings.nim) |
| Odin | [`odin/i/interleavingstrings.odin`](../../../odin/i/interleavingstrings.odin) |
| Rust | [`rust/i/interleavingstrings.rs`](../../../rust/i/interleavingstrings.rs) |
| V | [`v/i/interleavingstrings.v`](../../../v/i/interleavingstrings.v) |
| Zig | [`zig/i/interleavingstrings.zig`](../../../zig/i/interleavingstrings.zig) |
