# Remove stars

This benchmark ports the pinned Java `removeStars` string routine. It scans left to right; each `*` removes the most recent surviving character, and a star with no preceding character is ignored.

## Contract

- Input is `[text_length, ASCII bytes...]`, with length 0 through 4,096 and byte values 0 through 127.
- Output is the remaining bytes in order. Input is not modified. The result length is returned; malformed input returns -1 and insufficient output capacity returns -2.
- The bounded contract preserves the Java routine's behavior for ASCII. Unicode UTF-16 code-unit behavior is outside this benchmark.
- Time and auxiliary space are O(n).

## Workload

[`workload.json`](workload.json) covers empty input, the pinned example, leading and repeated stars, unchanged bytes, malformed input, and insufficient output capacity. The runtime oracle is [`benchmarks/remove_stars_oracle.py`](../../remove_stars_oracle.py).

## Pinned source

[TheAlgorithms/Java `RemoveStars.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/RemoveStars.java)

## Implementations

| Language | Source |
|---|---|
| C | [`c/r/remove_stars.c`](../../../c/r/remove_stars.c) |
| C3 | [`c3/r/remove_stars.c3`](../../../c3/r/remove_stars.c3) |
| C++ | [`cpp/r/remove_stars.cpp`](../../../cpp/r/remove_stars.cpp) |
| Elisa | [`elisa/r/remove_stars.elisa`](../../../elisa/r/remove_stars.elisa) |
| Nim | [`nim/r/remove_stars.nim`](../../../nim/r/remove_stars.nim) |
| Odin | [`odin/r/remove_stars.odin`](../../../odin/r/remove_stars.odin) |
| Rust | [`rust/r/remove_stars.rs`](../../../rust/r/remove_stars.rs) |
| V | [`v/r/remove_stars.v`](../../../v/r/remove_stars.v) |
| Zig | [`zig/r/remove_stars.zig`](../../../zig/r/remove_stars.zig) |
