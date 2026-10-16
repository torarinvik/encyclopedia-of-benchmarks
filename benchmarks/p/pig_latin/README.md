# Pig Latin

The pinned Python function lowercases a word. If its first character is a vowel, it appends `way`; otherwise it moves the prefix before the first vowel to the end and appends `ay`. Its whitespace-only input special case returns an empty string.

## Contract

Input is `[byte_count, ASCII letters...]`, with at most 64 letters. Empty input returns an empty output. For nonempty input, ASCII uppercase is lowercased and the word must contain at least one vowel from `aeiou`; consonant-only and non-letter inputs return `-1`. The benchmark restricts to a single word, excluding the pinned implementation's broader Unicode and whitespace behavior.

See [`workload.json`](workload.json) and the runtime [oracle](../../pig_latin_oracle.py). Pinned source: [TheAlgorithms/Python `pig_latin.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/pig_latin.py).

| Language | Port |
|---|---|
| C | [`c/p/pig_latin.c`](../../../c/p/pig_latin.c) |
| C3 | [`c3/p/pig_latin.c3`](../../../c3/p/pig_latin.c3) |
| C++ | [`cpp/p/pig_latin.cpp`](../../../cpp/p/pig_latin.cpp) |
| Elisa | [`elisa/p/pig_latin.elisa`](../../../elisa/p/pig_latin.elisa) |
| Nim | [`nim/p/pig_latin.nim`](../../../nim/p/pig_latin.nim) |
| Odin | [`odin/p/pig_latin.odin`](../../../odin/p/pig_latin.odin) |
| Rust | [`rust/p/pig_latin.rs`](../../../rust/p/pig_latin.rs) |
| V | [`v/p/pig_latin.v`](../../../v/p/pig_latin.v) |
| Zig | [`zig/p/pig_latin.zig`](../../../zig/p/pig_latin.zig) |
