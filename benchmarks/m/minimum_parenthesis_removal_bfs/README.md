# Minimum parenthesis removal by breadth-first search

This bounded profile repairs a lowercase ASCII string containing parentheses by deleting the fewest parentheses possible, then returning every distinct repaired string.

Input is `[text_length, ASCII_bytes...]`, with `0 <= text_length <= 16`, bytes in `a..z`, `(`, or `)`, and at most eight parentheses. Only parentheses may be deleted. Results are distinct and sorted lexicographically by unsigned ASCII byte order. An empty input returns one empty result.

The primary traverses deletion-mask states in breadth-first layers by number of removed parentheses. It validates each retained string, deduplicates equal strings from different masks, and stops after finishing the first successful layer. The independent reference first computes the exact number of unmatched opening and closing parentheses, then backtracks only over choices that remove those counts while keeping a nonnegative balance.

Output is a `u16` little-endian result count followed by one `u8` length and the ASCII bytes for each result. The maximum input frame is 17 valid and 18 parseable signed-64-bit values. Since at most eight parentheses can be deleted, there are at most 256 candidate strings; the output bound is 4,354 bytes and fixed workspace is 8,192 bytes. Malformed input returns `-1` before output-null/capacity checks; a null or short output buffer returns `-2`. Errors do not write output.

The [LeetCode 301 public title](https://leetcode.com/problems/remove-invalid-parentheses/) and a generic [breadth-first repair description](https://www.geeksforgeeks.org/dsa/remove-invalid-parentheses/) were discovery context only. This package uses no LeetCode task text, examples, tests, submissions, or code, and no GfG code or prose. The input/output contract and fixtures were independently authored.

## Language ports

| Language | Source |
|---|---|
| C | [`c/m/minimum_parenthesis_removal_bfs.c`](../../../c/m/minimum_parenthesis_removal_bfs.c) |
| C3 | [`c3/m/minimum_parenthesis_removal_bfs.c3`](../../../c3/m/minimum_parenthesis_removal_bfs.c3) |
| C++ | [`cpp/m/minimum_parenthesis_removal_bfs.cpp`](../../../cpp/m/minimum_parenthesis_removal_bfs.cpp) |
| Elisa | [`elisa/m/minimum_parenthesis_removal_bfs.elisa`](../../../elisa/m/minimum_parenthesis_removal_bfs.elisa) |
| Mojo | [`mojo/m/minimum_parenthesis_removal_bfs.mojo`](../../../mojo/m/minimum_parenthesis_removal_bfs.mojo) |
| Nim | [`nim/m/minimum_parenthesis_removal_bfs.nim`](../../../nim/m/minimum_parenthesis_removal_bfs.nim) |
| Odin | [`odin/m/minimum_parenthesis_removal_bfs.odin`](../../../odin/m/minimum_parenthesis_removal_bfs.odin) |
| Rust | [`rust/m/minimum_parenthesis_removal_bfs.rs`](../../../rust/m/minimum_parenthesis_removal_bfs.rs) |
| V | [`v/m/minimum_parenthesis_removal_bfs.v`](../../../v/m/minimum_parenthesis_removal_bfs.v) |
| Zig | [`zig/m/minimum_parenthesis_removal_bfs.zig`](../../../zig/m/minimum_parenthesis_removal_bfs.zig) |

See [`workload.json`](workload.json), [`RIGHTS.md`](RIGHTS.md), and [`INVENTORY.md`](INVENTORY.md). All package and suite review is static; no executable checks were run.
Static review corrected Zig's insertion sort to compare each displaced row with
its saved key, and made Nim's C-size length conversions explicit.
