# Longest common substring via suffix automaton (in progress)

Return the length of the longest contiguous sequence shared by two strings.
Build a suffix automaton of the first string and scan the second, following
suffix links when a transition is missing. Track the current match length and
the greatest length observed. This solves the same operation as
[`longest_common_substring`](../longest_common_substring/README.md), whose
ports use quadratic dynamic programming; the automaton construction and scan
are a distinct computational method.

The `i64_array_scalar` input matches that package: `[length_a,A...,length_b,B...]`,
with `0<=length_a,length_b<=256`, printable ASCII values `32..126`, and exact
frame length. Return the maximum common-substring length, or `-1` for malformed
input. The maximum valid frame has 514 i64 words and the maximum parseable
frame has 515, allowing a trailing-word error check. Empty strings return zero.
With a fixed alphabet, the method takes O(length_a+length_b) time and
O(length_a*95) space for its transition table.

Source: [CP-Algorithms, suffix automaton applications](https://cp-algorithms.com/string/suffix-automaton.html).
The article is CC BY-SA 4.0 and supplies the mathematical method only; no code,
prose, examples, or tests are copied.

**Status:** contract, workload, two oracle drafts, ten language drafts and
scalar-suite registration are present. The verifier source includes exhaustive
small binary-string pairs, maximum-length identity and malformed frames.
Nothing has been executed; validation remains.

| Language | Draft |
| --- | --- |
| C | [`c/l/longest_common_substring_sam.c`](../../../c/l/longest_common_substring_sam.c) |
| C3 | [`c3/l/longest_common_substring_sam.c3`](../../../c3/l/longest_common_substring_sam.c3) |
| C++ | [`cpp/l/longest_common_substring_sam.cpp`](../../../cpp/l/longest_common_substring_sam.cpp) |
| Elisa | [`elisa/l/longest_common_substring_sam.elisa`](../../../elisa/l/longest_common_substring_sam.elisa) |
| Mojo | [`mojo/l/longest_common_substring_sam.mojo`](../../../mojo/l/longest_common_substring_sam.mojo) |
| Nim | [`nim/l/longest_common_substring_sam.nim`](../../../nim/l/longest_common_substring_sam.nim) |
| Odin | [`odin/l/longest_common_substring_sam.odin`](../../../odin/l/longest_common_substring_sam.odin) |
| Rust | [`rust/l/longest_common_substring_sam.rs`](../../../rust/l/longest_common_substring_sam.rs) |
| V | [`v/l/longest_common_substring_sam.v`](../../../v/l/longest_common_substring_sam.v) |
| Zig | [`zig/l/longest_common_substring_sam.zig`](../../../zig/l/longest_common_substring_sam.zig) |
