# Reverse string

This benchmark reverses the bytes of a string. It follows the shared behavior of the pinned Dart, Java, JavaScript, and PHP implementations over printable non-whitespace ASCII. The domain excludes PHP's trimmed edge whitespace and restricts the string to one byte per character.

Source candidates: [Dart](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/strings/reverse_string.dart), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/ReverseString.java), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/String/ReverseString.js), and [PHP](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Strings/ReverseString.php).

## Contract

Input is a signed-i64 array [byte_length, ASCII bytes...]. The declared byte length is 0 through 256, the array length is exactly byte_length + 1, and each byte is in the range 0x21 through 0x7e. Empty input is valid. The function reverses the bytes without changing the input.

Output is the reversed ASCII string followed by one NUL byte. The function returns the number of output bytes before the terminator, -1 for malformed input, or -2 if the output buffer cannot hold the string and terminator. Failures do not write output. The maximum required output capacity is 257 bytes.

The sources reverse strings using split/reverse/join, Java's StringBuilder, indexed character traversal, or PHP str_split/trim. On this bounded ASCII input, each source returns the same byte sequence, including for the empty string.

The [workload](workload.json) covers empty and one-byte strings, mixed case and punctuation, repeated characters, the maximum length, malformed input, and insufficient output capacity.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/r/reverse_string.c](../../../c/r/reverse_string.c) |
| C3 | [c3/r/reverse_string.c3](../../../c3/r/reverse_string.c3) |
| C++ | [cpp/r/reverse_string.cpp](../../../cpp/r/reverse_string.cpp) |
| Elisa | [elisa/r/reverse_string.elisa](../../../elisa/r/reverse_string.elisa) |
| Nim | [nim/r/reverse_string.nim](../../../nim/r/reverse_string.nim) |
| Odin | [odin/r/reverse_string.odin](../../../odin/r/reverse_string.odin) |
| Rust | [rust/r/reverse_string.rs](../../../rust/r/reverse_string.rs) |
| V | [v/r/reverse_string.v](../../../v/r/reverse_string.v) |
| Zig | [zig/r/reverse_string.zig](../../../zig/r/reverse_string.zig) |
