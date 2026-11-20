# Parameterized pattern matching with modified KMP

This profile finds every substring of a text whose equality pattern matches a
pattern under a one-to-one renaming of symbols. It measures the alphabet-
dependent modified KMP search kernel: the implementation builds the pattern's
previous-occurrence table and failure links, then scans the text with mapped-
match predicates. It does not compare predecessor strings independently at
each candidate window.

The frame is `[n,m,sigma,T[0..n),P[0..m)]`, where `0 <= n <= 64`,
`1 <= m <= 16`, `1 <= sigma <= 16`, and every symbol is in `[0,sigma)`. The
frame has exactly `3+n+m` signed-i64 words. `n=0` and `m>n` are valid and
produce no matches. A malformed frame or symbol returns `-1`. Success returns
the byte count and writes `[count,start_0,...]` as little-endian signed-i64
words; starts are zero-based and ascending. A null output or insufficient
capacity returns `-2` without writing.

For pattern position `i`, let `prev[i]` be the preceding position of the same
pattern symbol, or `-1` if it is the first occurrence. To construct KMP failure
links, comparing pattern position `i` with prefix position `j` checks whether
the symbol is new in both compared prefixes when `prev[i] < 0` or
`i-prev[i] > j`; otherwise it checks
`P[j] == P[j-(i-prev[i])]`. During the text scan, a first occurrence at
pattern position `j` matches only if the current text symbol has no occurrence
at or after the candidate window start `text_position-j`. A repeated pattern
symbol matches when the text symbol equals the one at the same previous-
occurrence distance. Failure links handle mismatches and preserve overlapping
matches.

The primary modified-KMP reference uses `O(n+m+sigma)` time and
`O(m+sigma)` auxiliary space for this bounded alphabet-array profile. The
independent reference enumerates windows and checks two-way symbol maps in
`O((n-m+1)m)` time and `O(sigma)` auxiliary space. Its direct per-window
method does not use KMP failure links. The pre-existing
[`parameterized_pattern_matching`](../parameterized_pattern_matching/README.md)
profile uses predecessor-string equality for each window; this package's
failure-link construction and streaming text scan are a distinct algorithmic
kernel. The larger Chapter 282 topics, including parameterized suffix trees,
approximate matching, and two-dimensional matching, remain outside this
bounded profile.

## Bounds and workload

The maximum valid frame is `3+64+16 = 83` words. The parser accepts up to 84
words so a trailing-word malformed frame can be represented. There can be at
most 64 matches, so the maximum output is `8*(1+64) = 520` bytes. The declared
workspace cap is 4,096 bytes, including bounded source arrays and staged
output, excluding caller-owned input and output buffers.

[`workload.json`](workload.json) pins renamed matches, failure-link fallback,
overlaps, bijection rejection, empty text, a maximum-size valid input,
maximum output rejected at one byte below capacity, malformed symbols and
framing, a signed-minimum symbol, null buffers, and insufficient capacity. The
two oracles and static metadata helpers are listed in
[`INVENTORY.md`](INVENTORY.md).

## Sources and duplicate decision

The operational modified-KMP comparison predicates and failure-link method
come from Amir, Farach, and Muthukrishnan, “Alphabet Dependence in
Parameterized Matching,” §2, DOI
[`10.1016/0020-0190(94)90086-8`](https://doi.org/10.1016/0020-0190(94)90086-8).
Chapter 282, Moshe Lewenstein, “Parameterized Pattern Matching,” DOI
[`10.1007/978-1-4939-2864-4_282`](https://doi.org/10.1007/978-1-4939-2864-4_282),
provides the Encyclopedia crosswalk. The package is clean-room: sources inform
the algorithm and contract only; no source code, examples, tests, figures, or
prose were copied. See [`RIGHTS.md`](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [parameterized_pattern_matching_kmp.c](../../../c/p/parameterized_pattern_matching_kmp.c) |
| C3 | [parameterized_pattern_matching_kmp.c3](../../../c3/p/parameterized_pattern_matching_kmp.c3) |
| C++ | [parameterized_pattern_matching_kmp.cpp](../../../cpp/p/parameterized_pattern_matching_kmp.cpp) |
| Elisa | [parameterized_pattern_matching_kmp.elisa](../../../elisa/p/parameterized_pattern_matching_kmp.elisa) |
| Mojo | [parameterized_pattern_matching_kmp.mojo](../../../mojo/p/parameterized_pattern_matching_kmp.mojo) |
| Nim | [parameterized_pattern_matching_kmp.nim](../../../nim/p/parameterized_pattern_matching_kmp.nim) |
| Odin | [parameterized_pattern_matching_kmp.odin](../../../odin/p/parameterized_pattern_matching_kmp.odin) |
| Rust | [parameterized_pattern_matching_kmp.rs](../../../rust/p/parameterized_pattern_matching_kmp.rs) |
| V | [parameterized_pattern_matching_kmp.v](../../../v/p/parameterized_pattern_matching_kmp.v) |
| Zig | [parameterized_pattern_matching_kmp.zig](../../../zig/p/parameterized_pattern_matching_kmp.zig) |

All ten ports expose `parameterized_pattern_matching_kmp` with the
`i64_array_bytes_output` ABI. Shared suite and catalog registration are
coordinated separately.
