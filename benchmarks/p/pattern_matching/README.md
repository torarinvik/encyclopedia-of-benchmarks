# Pattern matching

## Contract

Input is `[text_length, text bytes..., pattern_length, pattern bytes...]`. Both strings are ASCII with bytes 0–127; text length is 0–64 and pattern length is 1–64. Return the first zero-based start index of the pattern, or `-1` if it does not occur. Malformed input also returns `-1`. Empty patterns are outside the contract.

The benchmark follows the pinned naive left-to-right comparison. It is case-sensitive: the source's comment says inputs are converted to lowercase, but its executable code performs no such conversion. On a match, it returns immediately at the first starting index.

## Source review

The pinned JavaScript `checkIfPatternExists` iterates candidate start positions through `textLength-patternLength`, compares characters one by one, breaks on mismatch, and returns a formatted message containing the first index. The benchmark maps that message to its numeric index. Its inner loop is bounded by text length rather than pattern length, but a match is returned as soon as the pattern's last character matches. The benchmark excludes empty patterns, for which the source does not return a match message.

Pinned source: [JavaScript `PatternMatching.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/String/PatternMatching.js).

## Workload and implementations

[`workload.json`](workload.json) includes first/middle matches, overlapping matches, case-sensitive behavior, absence, empty text, too-long and empty patterns, and malformed input. The [runtime oracle](../../pattern_matching_oracle.py) implements the same bounded search.

| Language | Port |
|---|---|
| C | [`c/p/pattern_matching.c`](../../../c/p/pattern_matching.c) |
| C3 | [`c3/p/pattern_matching.c3`](../../../c3/p/pattern_matching.c3) |
| C++ | [`cpp/p/pattern_matching.cpp`](../../../cpp/p/pattern_matching.cpp) |
| Elisa | [`elisa/p/pattern_matching.elisa`](../../../elisa/p/pattern_matching.elisa) |
| Nim | [`nim/p/pattern_matching.nim`](../../../nim/p/pattern_matching.nim) |
| Odin | [`odin/p/pattern_matching.odin`](../../../odin/p/pattern_matching.odin) |
| Rust | [`rust/p/pattern_matching.rs`](../../../rust/p/pattern_matching.rs) |
| V | [`v/p/pattern_matching.v`](../../../v/p/pattern_matching.v) |
| Zig | [`zig/p/pattern_matching.zig`](../../../zig/p/pattern_matching.zig) |
