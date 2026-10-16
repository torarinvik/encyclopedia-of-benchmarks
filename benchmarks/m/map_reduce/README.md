# Map-reduce word frequencies

This benchmark ports the pinned Java `MapReduce.countWordFrequencies` routine. It groups exact ASCII whitespace-delimited tokens, keeps each token's first-seen position, and emits each distinct token with its count.

## Contract

- The `i64_array_bytes_output` input is a raw array of 0 through 256 byte values. Values may be TAB, LF, VT, FF, CR, or printable ASCII (`32..126`); all other values are invalid.
- Leading and trailing whitespace is trimmed, and each internal run of ASCII whitespace separates tokens. Matching is case-sensitive; punctuation and digits remain part of tokens.
- Output is ASCII `word: count` entries joined by commas without spaces, in first-seen order. Empty or whitespace-only input follows Java's split behavior and produces `: 1`.
- Invalid input returns `-1`. Valid input with a null output pointer or insufficient output capacity returns `-2` without writing. Success returns the number of output bytes. The output workspace is at most 1024 bytes.

The independent byte-level oracle is [`map_reduce_oracle.py`](../../map_reduce_oracle.py); bounded examples and malformed inputs are in [`workload.json`](workload.json).

## Pinned source

[TheAlgorithms/Java `MapReduce.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/misc/MapReduce.java), commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`, method `countWordFrequencies(sentence)`.

## Ports

| Language | Source |
| --- | --- |
| C | [`c/map_reduce.c`](../../../c/m/map_reduce.c) |
| C3 | [`c3/map_reduce.c3`](../../../c3/m/map_reduce.c3) |
| C++ | [`cpp/map_reduce.cpp`](../../../cpp/m/map_reduce.cpp) |
| Elisa | [`elisa/map_reduce.elisa`](../../../elisa/m/map_reduce.elisa) |
| Nim | [`nim/map_reduce.nim`](../../../nim/m/map_reduce.nim) |
| Odin | [`odin/map_reduce.odin`](../../../odin/m/map_reduce.odin) |
| Rust | [`rust/map_reduce.rs`](../../../rust/m/map_reduce.rs) |
| V | [`v/map_reduce.v`](../../../v/m/map_reduce.v) |
| Zig | [`zig/map_reduce.zig`](../../../zig/m/map_reduce.zig) |
