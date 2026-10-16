# Pangram checker

Check whether an ASCII string contains every English letter at least once, ignoring case and nonletters. This follows the primary pinned Python `is_pangram` function; its faster variants agree on the bounded ASCII domain.

## Contract

- The `i64_array_scalar` ABI receives one ASCII code point per array element, with length 0 through 4,096 and values in `[0, 127]`.
- Return `1` if all 26 letters `a` through `z` appear, case-insensitively; otherwise return `0`. Spaces, punctuation, digits, NUL, and other ASCII controls are ignored.
- Return `-1` for an out-of-range code point or an array longer than 4,096.
- Empty input is not a pangram.

The Python source has three implementations. The primary `is_pangram` lowercases each character and counts only values from `a` through `z`; its set-based and flag-array variants produce the same result for ASCII. Their Unicode behavior is outside this cross-language contract.

[`workload.json`](workload.json) covers the pinned examples, mixed case, punctuation, controls, empty input, maximum length, and invalid inputs.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/i/is_pangram.c`](../../../c/i/is_pangram.c) |
| C3 | [`c3/i/is_pangram.c3`](../../../c3/i/is_pangram.c3) |
| C++ | [`cpp/i/is_pangram.cpp`](../../../cpp/i/is_pangram.cpp) |
| Elisa | [`elisa/i/is_pangram.elisa`](../../../elisa/i/is_pangram.elisa) |
| Nim | [`nim/i/is_pangram.nim`](../../../nim/i/is_pangram.nim) |
| Odin | [`odin/i/is_pangram.odin`](../../../odin/i/is_pangram.odin) |
| Rust | [`rust/i/is_pangram.rs`](../../../rust/i/is_pangram.rs) |
| V | [`v/i/is_pangram.v`](../../../v/i/is_pangram.v) |
| Zig | [`zig/i/is_pangram.zig`](../../../zig/i/is_pangram.zig) |

## TheAlgorithms source

- [Python `strings/is_pangram.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/is_pangram.py)
- [Java `Pangram.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/Pangram.java)
- [Julia `pangram.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/strings/pangram.jl)
- [Rust `pangram.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/string/pangram.rs)
