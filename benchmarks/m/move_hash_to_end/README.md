# move_hash_to_end

This benchmark ports the pinned Java method [`MoveHashToEnd.moveHashToEnd`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/MoveHashToEnd.java). It performs a stable partition: all characters other than `#` stay in their original order, followed by the same number of `#` characters. It returns a new string of the original length.

This is distinct from [`move_to_front`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/compression/MoveToFront.java), which encodes symbols using their current position in an alphabet and moves each symbol to the front.

## Contract

- Input is the signed-i64 array `[length, byte_0, ...]`. Length is in `0..256`, and exactly `length` ASCII code values in `0..127` must follow. The bounded domain includes embedded NUL bytes as data. Invalid input returns `-1`.
- Output is the transformed byte sequence with the original length. Insufficient capacity returns `-2`; success returns the number of bytes written. An empty input returns zero bytes.
- The transformation retains every non-`#` code value in source order and writes `#` (code 35) into the remaining suffix positions.
- The Java method also returns null for a null string; the packed ABI has no null-string representation, so null is outside this bounded input domain.

The independent oracle is [`benchmarks/move_hash_to_end_oracle.py`](../../move_hash_to_end_oracle.py). The workload includes the source example, empty and hash-only strings, stable ordering, embedded NUL, bounds, malformed input, and capacity edges.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/m/move_hash_to_end.c`](../../../c/m/move_hash_to_end.c) |
| C3 | [`c3/m/move_hash_to_end.c3`](../../../c3/m/move_hash_to_end.c3) |
| C++ | [`cpp/m/move_hash_to_end.cpp`](../../../cpp/m/move_hash_to_end.cpp) |
| Elisa | [`elisa/m/move_hash_to_end.elisa`](../../../elisa/m/move_hash_to_end.elisa) |
| Nim | [`nim/m/move_hash_to_end.nim`](../../../nim/m/move_hash_to_end.nim) |
| Odin | [`odin/m/move_hash_to_end.odin`](../../../odin/m/move_hash_to_end.odin) |
| Rust | [`rust/m/move_hash_to_end.rs`](../../../rust/m/move_hash_to_end.rs) |
| V | [`v/m/move_hash_to_end.v`](../../../v/m/move_hash_to_end.v) |
| Zig | [`zig/m/move_hash_to_end.zig`](../../../zig/m/move_hash_to_end.zig) |
