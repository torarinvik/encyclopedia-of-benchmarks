# Characters Same

Check whether every character in a string equals its first character, following the pinned Java implementation.

## Contract

- The `i64_array_scalar` ABI represents the string as an array of character values. The array length is the string length; no length prefix is included.
- The supported domain is 0 through 256 ASCII code units, each in `[0, 127]`. This bounded ASCII subset preserves Java `String.charAt` comparisons exactly.
- Return `1` if all values match the first value or the input is empty; return `0` if any value differs. Return `-1` for an overlength input or a value outside the ASCII range.

The source returns true for the empty string and exits at the first differing UTF-16 code unit. Non-ASCII Java strings are outside this portable contract.

[`workload.json`](workload.json) covers empty and singleton input, repeated characters, an early mismatch, the maximum length, and malformed code values. The shared `run_i64_array_scalar.py` recorder includes the `characters_same` oracle branch.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/characters_same.c`](../../../c/c/characters_same.c) |
| C3 | [`c3/c/characters_same.c3`](../../../c3/c/characters_same.c3) |
| C++ | [`cpp/c/characters_same.cpp`](../../../cpp/c/characters_same.cpp) |
| Elisa | [`elisa/c/characters_same.elisa`](../../../elisa/c/characters_same.elisa) |
| Nim | [`nim/c/characters_same.nim`](../../../nim/c/characters_same.nim) |
| Odin | [`odin/c/characters_same.odin`](../../../odin/c/characters_same.odin) |
| Rust | [`rust/c/characters_same.rs`](../../../rust/c/characters_same.rs) |
| V | [`v/c/characters_same.v`](../../../v/c/characters_same.v) |
| Zig | [`zig/c/characters_same.zig`](../../../zig/c/characters_same.zig) |

## Pinned source

- [Java `CharactersSame.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/CharactersSame.java)
