# Phonetic alphabet converter

The pinned Java `textToPhonetic` uppercases the input, skips characters for which `Character.isWhitespace` is true, maps A–Z and 0–9 to NATO-style words, passes other characters through, separates emitted tokens by one space, and trims the final string.

## Contract

Input is `[byte_count, ASCII_bytes...]`, with 0–64 bytes. The benchmark domain contains ASCII letters, digits, printable punctuation, and ASCII whitespace only; this avoids Java default-locale and Unicode uppercase expansions. It preserves punctuation, skips ASCII whitespace, and returns the exact joined ASCII output. Malformed input returns result -1; insufficient output capacity returns -2. Maximum output is 575 bytes.

See [`workload.json`](workload.json), the runtime [oracle](../../phonetic_alphabet_converter_oracle.py), and the [pinned Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/PhoneticAlphabetConverter.java).

| Language | Port |
|---|---|
| C | [`c/p/phonetic_alphabet_converter.c`](../../../c/p/phonetic_alphabet_converter.c) |
| C3 | [`c3/p/phonetic_alphabet_converter.c3`](../../../c3/p/phonetic_alphabet_converter.c3) |
| C++ | [`cpp/p/phonetic_alphabet_converter.cpp`](../../../cpp/p/phonetic_alphabet_converter.cpp) |
| Elisa | [`elisa/p/phonetic_alphabet_converter.elisa`](../../../elisa/p/phonetic_alphabet_converter.elisa) |
| Nim | [`nim/p/phonetic_alphabet_converter.nim`](../../../nim/p/phonetic_alphabet_converter.nim) |
| Odin | [`odin/p/phonetic_alphabet_converter.odin`](../../../odin/p/phonetic_alphabet_converter.odin) |
| Rust | [`rust/p/phonetic_alphabet_converter.rs`](../../../rust/p/phonetic_alphabet_converter.rs) |
| V | [`v/p/phonetic_alphabet_converter.v`](../../../v/p/phonetic_alphabet_converter.v) |
| Zig | [`zig/p/phonetic_alphabet_converter.zig`](../../../zig/p/phonetic_alphabet_converter.zig) |
