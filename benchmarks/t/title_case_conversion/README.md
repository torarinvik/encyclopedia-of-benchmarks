# Title case conversion

This benchmark implements the pinned JavaScript `titleCaseConversion` behavior on ASCII words. Each nonempty word is separated by exactly one ASCII space. At the start of a word, an ASCII lowercase letter is changed to uppercase; every later ASCII uppercase letter is changed to lowercase. Other letters stay unchanged. Empty input returns empty output.

The source splits only on the literal space character. A leading, trailing, or repeated space creates an empty word and the source then attempts to read that word's first character. The benchmark excludes those inputs; it also restricts letters to ASCII so each character is one output byte.

Pinned source: [TheAlgorithms/JavaScript `TitleCaseConversion.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Conversions/TitleCaseConversion.js).

## Contract

Input is a signed-i64 array `[byte_length, ASCII bytes...]`. The length is 0 through 256; the packed array contains exactly `byte_length + 1` values. Bytes may be ASCII letters (`A-Z`, `a-z`) and single spaces between words only. Empty input is valid. Other bytes and malformed spacing return `-1`.

Output is the transformed ASCII bytes followed by one NUL byte. The function returns the payload length, excluding the terminator; returns `-1` for malformed input; and returns `-2` when the output buffer cannot hold the payload and terminator. Invalid and short-buffer calls do not write output. Maximum required output capacity is 257 bytes.

The workload covers empty input, uppercase and lowercase words, mixed case, several words, maximum length, malformed spacing and bytes, a packing mismatch, and insufficient output capacity. All nine ports use the `i64_array_bytes_output` ABI.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/t/title_case_conversion.c](../../../c/t/title_case_conversion.c) |
| C3 | [c3/t/title_case_conversion.c3](../../../c3/t/title_case_conversion.c3) |
| C++ | [cpp/t/title_case_conversion.cpp](../../../cpp/t/title_case_conversion.cpp) |
| Elisa | [elisa/t/title_case_conversion.elisa](../../../elisa/t/title_case_conversion.elisa) |
| Nim | [nim/t/title_case_conversion.nim](../../../nim/t/title_case_conversion.nim) |
| Odin | [odin/t/title_case_conversion.odin](../../../odin/t/title_case_conversion.odin) |
| Rust | [rust/t/title_case_conversion.rs](../../../rust/t/title_case_conversion.rs) |
| V | [v/t/title_case_conversion.v](../../../v/t/title_case_conversion.v) |
| Zig | [zig/t/title_case_conversion.zig](../../../zig/t/title_case_conversion.zig) |
