# Reverse words

This benchmark reverses the order of words while preserving the bytes within each word. It follows the shared behavior of the pinned Python, JavaScript, F#, and PHP implementations on a bounded ASCII domain. Existing [`reverse_string_in_place`](../reverse_string_in_place/README.md) reverses characters and is a different operation.

Source candidates: [F#](https://github.com/TheAlgorithms/F-Sharp/blob/e5441e8bfd2cda87541634b75f39f0868447ae5f/Algorithms/Strings/ReverseWords.fs), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/String/ReverseWords.js), [PHP](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Strings/ReverseWords.php), and [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/reverse_words.py).

## Contract

Input is signed-i64 slots `[byte_length, ASCII bytes...]`, with `byte_length` from 0 through 256. Each word contains printable non-space ASCII bytes `0x21..0x7e`; words are separated by exactly one ASCII space, with no leading or trailing separator. Empty input and a single word are valid. The input array length must be exactly `byte_length + 1`.

Output is the reversed word sequence as ASCII bytes followed by a NUL byte. The function returns the output byte length, `-1` for malformed input, or `-2` if the output buffer cannot hold the bytes and terminator.

The source variants differ outside this domain: Python and JavaScript collapse whitespace runs, F# preserves empty split fields before joining with spaces, and PHP splits only literal spaces after trimming its own edge-whitespace set. This contract keeps the four implementations comparable on their shared behavior.

[`workload.json`](workload.json) covers empty input, one word, multiple words, punctuation, and uneven word lengths.

| Language | Source |
| --- | --- |
| C | [`c/r/reverse_words.c`](../../../c/r/reverse_words.c) |
| C3 | [`c3/r/reverse_words.c3`](../../../c3/r/reverse_words.c3) |
| C++ | [`cpp/r/reverse_words.cpp`](../../../cpp/r/reverse_words.cpp) |
| Elisa | [`elisa/r/reverse_words.elisa`](../../../elisa/r/reverse_words.elisa) |
| Nim | [`nim/r/reverse_words.nim`](../../../nim/r/reverse_words.nim) |
| Odin | [`odin/r/reverse_words.odin`](../../../odin/r/reverse_words.odin) |
| Rust | [`rust/r/reverse_words.rs`](../../../rust/r/reverse_words.rs) |
| V | [`v/r/reverse_words.v`](../../../v/r/reverse_words.v) |
| Zig | [`zig/r/reverse_words.zig`](../../../zig/r/reverse_words.zig) |
