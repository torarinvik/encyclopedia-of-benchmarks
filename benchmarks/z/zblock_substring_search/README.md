# Z-block substring search

The pinned C# `ZblockSubstringSearch.FindSubstring` builds a Z array for `pattern + "$" + text` and returns the number of positions whose Z value equals the pattern length. This benchmark keeps the all-occurrences count and Z-block algorithm while excluding `$` from the byte domain so the source separator cannot collide with input.

## Contract

The `i64_array_scalar` ABI receives `[text_length, pattern_length, text_bytes..., pattern_bytes...]`. Text length is 0–256; pattern length is 1–64; bytes are ASCII 0–127 except `$` (36). Exact byte equality is case-sensitive, and overlapping matches count separately. Invalid packed lengths, bounds, or bytes return `-1`. The algorithm forms the pattern/separator/text sequence, computes Z values in O(n+m) time and O(n+m) auxiliary space, then returns the number of text positions with a full pattern match.

[`workload.json`](workload.json) includes overlapping and repeated matches, misses, empty text, a longer pattern, NUL bytes, and invalid inputs. The existing [`z_algorithm_search`](../z_algorithm_search/README.md) returns a position list under a different case-insensitive contract, so it is not an alias.

## Pinned source

- [C-Sharp `ZblockSubstringSearch.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6/Algorithms/Strings/PatternMatching/ZblockSubstringSearch.cs)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/z/zblock_substring_search.c`](../../../c/z/zblock_substring_search.c) |
| C3 | [`c3/z/zblock_substring_search.c3`](../../../c3/z/zblock_substring_search.c3) |
| C++ | [`cpp/z/zblock_substring_search.cpp`](../../../cpp/z/zblock_substring_search.cpp) |
| Elisa | [`elisa/z/zblock_substring_search.elisa`](../../../elisa/z/zblock_substring_search.elisa) |
| Nim | [`nim/z/zblock_substring_search.nim`](../../../nim/z/zblock_substring_search.nim) |
| Odin | [`odin/z/zblock_substring_search.odin`](../../../odin/z/zblock_substring_search.odin) |
| Rust | [`rust/z/zblock_substring_search.rs`](../../../rust/z/zblock_substring_search.rs) |
| V | [`v/z/zblock_substring_search.v`](../../../v/z/zblock_substring_search.v) |
| Zig | [`zig/z/zblock_substring_search.zig`](../../../zig/z/zblock_substring_search.zig) |
