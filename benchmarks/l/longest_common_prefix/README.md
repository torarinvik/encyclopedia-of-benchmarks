# Longest common prefix

Find the longest prefix shared by all strings in an array. The pinned Java implementation sorts the array lexicographically, then compares the first and last strings. Its result is the same as the prefix shared by every input string. One input string returns that string; an empty array returns an empty string.

## Contract

- The `i64_array_bytes_output` input is `[count, length_0, bytes_0..., length_1, bytes_1..., ...]`.
- `count` is 0..16. Each string length is 0..64, each byte is an ASCII codepoint in 0..127, and the packed input must end exactly after the final string.
- The function returns the common-prefix byte length and writes those bytes to the output buffer. An empty array, an empty string in the input, or no shared leading byte produces length 0 and no output bytes.
- Invalid packing or values return `-1`. An output buffer smaller than the prefix, or a missing buffer when a nonempty prefix is required, returns `-2`.
- ASCII keeps Java's UTF-16 lexicographic order equivalent to byte order. The source sorts its input array in place; the packed ABI is read-only, so ports sort an internal index list and return the same prefix without exposing that side effect.

## Source and related algorithms

The source is the pinned Java [`LongestCommonPrefix.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/LongestCommonPrefix.java). It returns `""` for null or empty arrays; a null value inside a nonempty array causes the Java sort to fail, and null strings have no representation in this ABI. [`longest_common_substring`](../longest_common_substring/README.md) finds a contiguous match anywhere in two strings, while this package finds a prefix shared by an array.

[`workload.json`](workload.json) covers empty and singleton arrays, a shared prefix, no shared prefix, empty strings, embedded NUL, maximum string length, and malformed inputs. The output is the prefix bytes plus their length, using the shared `i64_array_bytes_output` ABI.

| Language | Source |
| --- | --- |
| C | [`c/l/longest_common_prefix.c`](../../../c/l/longest_common_prefix.c) |
| C3 | [`c3/l/longest_common_prefix.c3`](../../../c3/l/longest_common_prefix.c3) |
| C++ | [`cpp/l/longest_common_prefix.cpp`](../../../cpp/l/longest_common_prefix.cpp) |
| Elisa | [`elisa/l/longest_common_prefix.elisa`](../../../elisa/l/longest_common_prefix.elisa) |
| Nim | [`nim/l/longest_common_prefix.nim`](../../../nim/l/longest_common_prefix.nim) |
| Odin | [`odin/l/longest_common_prefix.odin`](../../../odin/l/longest_common_prefix.odin) |
| Rust | [`rust/l/longest_common_prefix.rs`](../../../rust/l/longest_common_prefix.rs) |
| V | [`v/l/longest_common_prefix.v`](../../../v/l/longest_common_prefix.v) |
| Zig | [`zig/l/longest_common_prefix.zig`](../../../zig/l/longest_common_prefix.zig) |
