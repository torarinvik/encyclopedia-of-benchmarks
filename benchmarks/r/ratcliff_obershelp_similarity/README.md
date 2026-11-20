# Ratcliff/Obershelp Gestalt similarity

Measure the similarity of two bounded ASCII byte strings by repeatedly finding
their longest common contiguous block, counting it, and continuing recursively
on the unmatched prefixes and suffixes. This score captures several aligned
blocks; it is distinct from [`longest_common_substring`](../../l/longest_common_substring/README.md),
which returns only one block's length, and from Jaro, Jaro–Winkler, and edit
distance metrics, which use different matching rules.

## Contract

The `i64_array_scalar` input is exactly
`[first_length, second_length, first_bytes..., second_bytes...]`. Each length
is in `0..32`; bytes are ASCII values `1..127`, compared case-sensitively.
The maximum valid frame is 66 words, and the maximum parseable frame is 67
words. Null, malformed, non-ASCII, NUL-containing, or out-of-range input
returns `-1`.

For each region pair, choose the longest common substring; ties use the
leftmost start in the first string, then the leftmost start in the second.
Recursively score the unmatched prefix pair and suffix pair, and sum the
matched character counts. Return
`floor(200 * matched_characters / (first_length + second_length))`, in `0..100`.
If either input is empty, the score is zero, including the both-empty case.
The fixed profile uses at most 16,384 bytes of workspace and has worst-case
`O(n*m*min(n,m))` time with `O(min(n,m))` auxiliary space.

## References and provenance

NIST DADS defines Ratcliff/Obershelp similarity as the longest common
substring followed recursively by matching the unmatched regions. The
original specification is Ratcliff and Metzener's [“Pattern Matching: The
Gestalt Approach”](https://jacobfilipp.com/DrDobbs/articles/DDJ/1988/8807/8807c/8807c.htm).
Its original procedure returns an integer percentage by dividing twice the
matched-character count by total input length. This benchmark makes the
longest-match tie rule explicit so all ports agree.

The primary reference uses one-row longest-common-substring dynamic
programming and recursion. The independent reference checks candidate
substrings directly and traverses the decomposition with an explicit stack.
The implementation and fixtures are clean-room; only the algorithm description
was used. See [RIGHTS.md](RIGHTS.md), the [workload](workload.json), and the
static inventory in [INVENTORY.md](INVENTORY.md). No checks or programs have
been run.

## Language ports

| Language | Source |
|---|---|
| C | [`ratcliff_obershelp_similarity.c`](../../../c/r/ratcliff_obershelp_similarity.c) |
| C3 | [`ratcliff_obershelp_similarity.c3`](../../../c3/r/ratcliff_obershelp_similarity.c3) |
| C++ | [`ratcliff_obershelp_similarity.cpp`](../../../cpp/r/ratcliff_obershelp_similarity.cpp) |
| Elisa | [`ratcliff_obershelp_similarity.elisa`](../../../elisa/r/ratcliff_obershelp_similarity.elisa) |
| Mojo | [`ratcliff_obershelp_similarity.mojo`](../../../mojo/r/ratcliff_obershelp_similarity.mojo) |
| Nim | [`ratcliff_obershelp_similarity.nim`](../../../nim/r/ratcliff_obershelp_similarity.nim) |
| Odin | [`ratcliff_obershelp_similarity.odin`](../../../odin/r/ratcliff_obershelp_similarity.odin) |
| Rust | [`ratcliff_obershelp_similarity.rs`](../../../rust/r/ratcliff_obershelp_similarity.rs) |
| V | [`ratcliff_obershelp_similarity.v`](../../../v/r/ratcliff_obershelp_similarity.v) |
| Zig | [`ratcliff_obershelp_similarity.zig`](../../../zig/r/ratcliff_obershelp_similarity.zig) |
