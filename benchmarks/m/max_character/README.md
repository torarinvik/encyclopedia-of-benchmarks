# Max Character

Return the lowercase ASCII letter that occurs most often in the input, following the common behavior of the pinned JavaScript and PHP sources on a bounded shared domain.

## Contract

- The `i64_array_scalar` ABI represents the string as an array of ASCII code values, with length 1 through 256 and each value in `[97, 122]` (`a` through `z`). There is no length prefix.
- The input must have a unique most-frequent letter. Return that letter's ASCII code from 97 through 122. Return `-1` for empty, overlength, out-of-domain, or tied-maximum input.
- Lowercase ASCII makes PHP's `strtolower` and byte-oriented `str_split` agree with JavaScript's case-sensitive character iteration. Requiring a unique maximum removes differences in how the sources break ties.

The JavaScript source also accepts an optional regular expression that excludes characters; the benchmark uses the no-pattern form. PHP rejects the exact string `"0"`; that value is outside this lowercase-letter contract.

[`workload.json`](workload.json) covers a singleton, repeated letters, a unique maximum, a tie, and invalid inputs. The current `run_i64_array_scalar.py` recorder needs a `max_character` oracle branch; runner files are outside this package.

## Pinned sources

- [JavaScript `MaxCharacter.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/String/MaxCharacter.js)
- [PHP `MaxCharacter.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Strings/MaxCharacter.php)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/m/max_character.c`](../../../c/m/max_character.c) |
| C3 | [`c3/m/max_character.c3`](../../../c3/m/max_character.c3) |
| C++ | [`cpp/m/max_character.cpp`](../../../cpp/m/max_character.cpp) |
| Elisa | [`elisa/m/max_character.elisa`](../../../elisa/m/max_character.elisa) |
| Nim | [`nim/m/max_character.nim`](../../../nim/m/max_character.nim) |
| Odin | [`odin/m/max_character.odin`](../../../odin/m/max_character.odin) |
| Rust | [`rust/m/max_character.rs`](../../../rust/m/max_character.rs) |
| V | [`v/m/max_character.v`](../../../v/m/max_character.v) |
| Zig | [`zig/m/max_character.zig`](../../../zig/m/max_character.zig) |
