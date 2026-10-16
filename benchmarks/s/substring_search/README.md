# substring_search

This benchmark ports the independent `searchSubString` helper in the pinned AArch64 assembly file [TheAlgorithms/AArch64_Assembly `string/substring.s`](https://github.com/TheAlgorithms/AArch64_Assembly/blob/cb138a856a3af14d3d3dfcd2743d43841eec566f/string/substring.s). It searches for one NUL-terminated byte string inside another and returns the first match's zero-based byte index.

## Contract

- The packed signed-i64 input is `[text_length, pattern_length, text_bytes..., pattern_bytes...]`.
- Text length is `0..128`; pattern length is `0..64`; the packed array must have exactly `2 + text_length + pattern_length` values. Byte values are nonzero ASCII `1..127`; zero is reserved for the source's terminating NUL.
- A found match returns its starting index. No match returns `-1`, including an empty pattern. Invalid packed input returns `-2`.
- The source advances the text index after a mismatch and resets the pattern index to zero without retrying the current byte as a new candidate. This preserves its missed-overlap behavior: searching for `aab` in `aaab` returns `-1`, even though the pattern occurs at index 1. The function stops at its first match rather than counting matches.

The input bounds make the explicit bytes equivalent to NUL-terminated ASCII strings. They exclude embedded NUL and non-ASCII bytes. This is a separate helper from the fixed-count substring copy benchmark in [`substring`](../substring/README.md).

## Source and workload

The benchmark follows the pinned `searchSubString` helper exactly on the bounded byte domain; no standard-library search routine is used as the behavioral reference. The independent oracle is [`benchmarks/substring_search_oracle.py`](../../substring_search_oracle.py). The workload includes ordinary matches, post-mismatch matches, the overlap quirk, empty and absent patterns, boundary sizes, and invalid packed input.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/substring_search.c`](../../../c/s/substring_search.c) |
| C3 | [`c3/s/substring_search.c3`](../../../c3/s/substring_search.c3) |
| C++ | [`cpp/s/substring_search.cpp`](../../../cpp/s/substring_search.cpp) |
| Elisa | [`elisa/s/substring_search.elisa`](../../../elisa/s/substring_search.elisa) |
| Nim | [`nim/s/substring_search.nim`](../../../nim/s/substring_search.nim) |
| Odin | [`odin/s/substring_search.odin`](../../../odin/s/substring_search.odin) |
| Rust | [`rust/s/substring_search.rs`](../../../rust/s/substring_search.rs) |
| V | [`v/s/substring_search.v`](../../../v/s/substring_search.v) |
| Zig | [`zig/s/substring_search.zig`](../../../zig/s/substring_search.zig) |
