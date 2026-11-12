# Crochemore–Perrin Two-Way string matching

This package reports every exact byte-pattern occurrence using the Two-Way
algorithm. It computes maximal suffixes under both alphabet orders to select a
critical factorization. The scan compares right of the split first, checks the
left part after a full right-side match, and uses either period-memory shifts
or the nonperiodic critical-factorization shift.

## Bounded contract

The `i64_array_bytes_output` entry point is
`crochemore_perrin_two_way(input, length, output, capacity) -> i64`. Input is
`[text_length, pattern_length, text_bytes..., pattern_bytes...]`, with text
length `0..=64`, pattern length `0..=32`, symbols `0..=255`, and exactly
`2 + text_length + pattern_length` signed 64-bit values. The output is the
increasing list of zero-based match starts, encoded as little-endian signed
64-bit integers. An empty pattern matches every boundary from `0` through the
text length. Invalid input returns `-1`; a null output pointer or insufficient
capacity returns `-2` without writing. A valid call with no matches returns
zero bytes. Maximum output is 520 bytes, and the workspace budget is 4,096
bytes including the staged match list.

For pattern length `m` and text length `n`, critical-factorization
preprocessing is `O(m)`, and the Two-Way search is `O(n + m)` time with
constant auxiliary state, excluding the `O(k)` result storage for `k` matches.

## Distinction and verification

[`prefix_function`](../p/prefix_function/README.md) computes KMP border values;
[`horspool_search`](../../h/horspool_search/README.md) and
[`boyer_moore`](../b/boyer_moore/README.md) use bad-character/good-suffix
shifts; [`string_match_finite_automata`](../s/string_match_finite_automata/README.md)
uses a transition table; and [`substring_search`](../s/substring_search/README.md)
directly scans candidates. This package instead uses critical factorization
and the Two-Way period/memory rule.

The [primary oracle](primary_oracle.py) implements the Two-Way factorization
and scan. The [independent oracle](independent_oracle.py) checks each candidate
start by direct byte comparison. The [workload](workload.json) covers empty
patterns and texts, overlapping and periodic matches, right-half mismatches,
NUL/high bytes, maximum text length, malformed frames, null buffers, and short
capacity. [`verify_workload.py`](verify_workload.py) statically checks fixtures,
metadata, rights, provenance, and the ten port paths.

## Provenance

The algorithm is from Maxime Crochemore and Dominique Perrin, “Two-way
string-matching,” *Journal of the ACM* 38(3), 651–675, 1991,
[DOI 10.1145/116825.116845](https://doi.org/10.1145/116825.116845). The paper’s
algorithm description was used for discovery and attribution only. The ports,
contract, workload, and oracles are clean-room. See [`RIGHTS.md`](RIGHTS.md).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/crochemore_perrin_two_way.c`](../../../c/crochemore_perrin_two_way.c) |
| C3 | [`c3/c/crochemore_perrin_two_way.c3`](../../../c3/c/crochemore_perrin_two_way.c3) |
| C++ | [`cpp/c/crochemore_perrin_two_way.cpp`](../../../cpp/c/crochemore_perrin_two_way.cpp) |
| Elisa | [`elisa/c/crochemore_perrin_two_way.elisa`](../../../elisa/c/crochemore_perrin_two_way.elisa) |
| Mojo | [`mojo/c/crochemore_perrin_two_way.mojo`](../../../mojo/c/crochemore_perrin_two_way.mojo) |
| Nim | [`nim/c/crochemore_perrin_two_way.nim`](../../../nim/c/crochemore_perrin_two_way.nim) |
| Odin | [`odin/c/crochemore_perrin_two_way.odin`](../../../odin/c/crochemore_perrin_two_way.odin) |
| Rust | [`rust/c/crochemore_perrin_two_way.rs`](../../../rust/c/crochemore_perrin_two_way.rs) |
| V | [`v/c/crochemore_perrin_two_way.v`](../../../v/c/crochemore_perrin_two_way.v) |
| Zig | [`zig/c/crochemore_perrin_two_way.zig`](../../../zig/c/crochemore_perrin_two_way.zig) |
