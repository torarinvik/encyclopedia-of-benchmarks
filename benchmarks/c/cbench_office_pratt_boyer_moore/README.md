# cBench Pratt–Boyer–Moore string search

This package ports only `init_search` and `strsearch` from the pinned
`pbmsrch_large.c`. The source describes the helper as a Pratt–Boyer–Moore
string search and explicitly places it in the Public Domain by Jerry Coffin.
The file/CLI harness and cBench's larger workload are not part of this
standalone profile.

## Contract

Export `cbench_office_pratt_boyer_moore` with the `i64_array_scalar` ABI.
Input is `[text_length, pattern_length, text_bytes..., pattern_bytes...]`.
Text length is 0 through 255; pattern length is 1 through 64; the packed input
must have exactly `2 + text_length + pattern_length` values. Text and pattern
bytes are non-NUL ASCII values 1 through 127. The result is the first
zero-based match offset, or `-1` when the pattern is absent. Malformed input
returns `-2`.

The port preserves the source's endpoint skip table. Every byte starts with
shift `pattern_length`; each pattern byte overwrites its shift with
`pattern_length - index - 1`, including a zero shift for the final pattern
byte. Search advances text endpoints by positive shifts. At a zero shift it
compares the entire pattern at the implied window; if that endpoint was a
false positive, it advances by one. This is the source's bounded helper
behavior, not a claim that it implements textbook full Boyer–Moore or its
good-suffix rule. Empty patterns are excluded because the C source's
`size_t` endpoint initialization underflows for that case.

## Pinned source and rights

- Launcher: [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/office_stringsearch1/src/info.sh)
- Algorithm helper: [`pbmsrch_large.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/office_stringsearch1/src/pbmsrch_large.c)
- Pinned commit: `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`

The selected helper's source header explicitly places it in the Public Domain.
Its complete attribution and permission notice is retained in each port and
[`LICENSE.txt`](LICENSE.txt). No launcher file-handling or CLI code is copied.

```text
/* +++Date last modified: 05-Jul-1997 */

/*
**        A Pratt-Boyer-Moore string search, written by Jerry Coffin
**  sometime or other in 1991.  Removed from original program, and
**  (incorrectly) rewritten for separate, generic use in early 1992.
**  Corrected with help from Thad Smith, late March and early
**  April 1992...hopefully it's correct this time. Revised by Bob Stout.
**
**  This is hereby placed in the Public Domain by its author.
**
**  10/21/93 rdg  Fixed bug found by Jeff Dunlop
*/
```

## Workload and ports

[`workload.json`](workload.json) contains match, absent, maximum-bound, endpoint
false-positive, and malformed-input cases. The independent scalar model is
[`cbench_office_pratt_boyer_moore_oracle.py`](../../cbench_office_pratt_boyer_moore_oracle.py).

| Language | Port |
|---|---|
| C | [`c/c/cbench_office_pratt_boyer_moore.c`](../../../c/c/cbench_office_pratt_boyer_moore.c) |
| C3 | [`c3/c/cbench_office_pratt_boyer_moore.c3`](../../../c3/c/cbench_office_pratt_boyer_moore.c3) |
| C++ | [`cpp/c/cbench_office_pratt_boyer_moore.cpp`](../../../cpp/c/cbench_office_pratt_boyer_moore.cpp) |
| Elisa | [`elisa/c/cbench_office_pratt_boyer_moore.elisa`](../../../elisa/c/cbench_office_pratt_boyer_moore.elisa) |
| Nim | [`nim/c/cbench_office_pratt_boyer_moore.nim`](../../../nim/c/cbench_office_pratt_boyer_moore.nim) |
| Odin | [`odin/c/cbench_office_pratt_boyer_moore.odin`](../../../odin/c/cbench_office_pratt_boyer_moore.odin) |
| Rust | [`rust/c/cbench_office_pratt_boyer_moore.rs`](../../../rust/c/cbench_office_pratt_boyer_moore.rs) |
| V | [`v/c/cbench_office_pratt_boyer_moore.v`](../../../v/c/cbench_office_pratt_boyer_moore.v) |
| Zig | [`zig/c/cbench_office_pratt_boyer_moore.zig`](../../../zig/c/cbench_office_pratt_boyer_moore.zig) |
