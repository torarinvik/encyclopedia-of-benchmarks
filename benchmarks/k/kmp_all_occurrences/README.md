# KMP all occurrences

Find every occurrence of an ASCII pattern in an ASCII text using the Knuth–Morris–Pratt prefix table, preserving overlapping matches.

## Contract

The i64_array_bytes_output input is [text_length, pattern_length, text_ascii..., pattern_ascii...]. Text length is 0..256, pattern length is 1..64, and every character code is ASCII 0..127. The packed input contains exactly 2 + text_length + pattern_length signed 64-bit values. An empty pattern is invalid; an empty text is valid and has no matches.

The algorithm returns every zero-based match start in ascending order. After a match, it falls back to the longest proper prefix that is also a suffix, so overlapping occurrences are included. Output is one signed little-endian 64-bit index per match, and the return value is the number of output bytes written. Invalid input returns -1. A null output pointer returns -2 even when there are no matches. A nonnull zero-capacity output succeeds when no matches are produced. A short buffer returns -2 without writing bytes.

ASCII keeps character positions aligned with byte positions. The bounds allow at most 256 matches and 2,048 output bytes. The prefix construction and search together run in O(text_length + pattern_length).

## Workload and oracle

[workload.json](workload.json) covers single and repeated matches, overlapping matches, prefix fallback, ASCII boundary codes, empty text, no-match and long-pattern cases, maximum text/pattern/output sizes, null and capacity behavior, and malformed inputs. The independent [oracle](../../kmp_all_occurrences_oracle.py) returns the exact little-endian offset vector.

## Pinned source

The source is [TheAlgorithms/JavaScript StringSearch.js at 5c39e87a9a31f279c60f830ad74a845e4788a517](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Search/StringSearch.js), function stringSearch. Its prefix fallback emits every match in order and retains the matched prefix after emission, which preserves overlaps.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/k/kmp_all_occurrences.c](../../../c/k/kmp_all_occurrences.c) |
| C3 | [c3/k/kmp_all_occurrences.c3](../../../c3/k/kmp_all_occurrences.c3) |
| C++ | [cpp/k/kmp_all_occurrences.cpp](../../../cpp/k/kmp_all_occurrences.cpp) |
| Elisa | [elisa/k/kmp_all_occurrences.elisa](../../../elisa/k/kmp_all_occurrences.elisa) |
| Nim | [nim/k/kmp_all_occurrences.nim](../../../nim/k/kmp_all_occurrences.nim) |
| Odin | [odin/k/kmp_all_occurrences.odin](../../../odin/k/kmp_all_occurrences.odin) |
| Rust | [rust/k/kmp_all_occurrences.rs](../../../rust/k/kmp_all_occurrences.rs) |
| V | [v/k/kmp_all_occurrences.v](../../../v/k/kmp_all_occurrences.v) |
| Zig | [zig/k/kmp_all_occurrences.zig](../../../zig/k/kmp_all_occurrences.zig) |
