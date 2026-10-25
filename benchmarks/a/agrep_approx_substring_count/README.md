# Agrep Approximate Substring Count

This bounded package measures approximate substring search, the core operation
behind the `agrep` candidate in the pinned LAC-DCC Prolangs-C suite. For each
text byte, it finds the minimum unit-cost Levenshtein distance between the full
pattern and any substring ending at that byte, then counts the positions whose
distance is at most the requested error allowance. The implementation uses a
streaming dynamic-programming row with a free restart at each text position.

This is not whole-string Levenshtein distance: its row-zero cell is reset for
each input byte, so a match may start anywhere in the text. It is not exact
Bitap: the allowance includes insertion, deletion, and substitution errors,
and the result counts every qualifying end position rather than returning the
first exact match.

## Contract

The signed 64-bit input array is
`[pattern_length, text_length, max_errors, pattern_bytes..., text_bytes...]`.
Pattern length is 1–63 bytes, text length is 0–4,096 bytes, and `max_errors`
is 0–2. Every pattern and text byte must be printable ASCII (32–126); the
packed array length must equal `3 + pattern_length + text_length`. The function
returns the number of text positions whose best approximate match ending at
that position is within the allowance. An empty text returns zero. Malformed
inputs return -2.

The workload uses one record per call. Newlines and multi-file/CLI behavior are
outside this bounded core contract.

## Provenance and rights

The source candidate is [`Prolangs-C/agrep`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/agrep), pinned at commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Its `bitap.c` and `asearch.c`
headers state “Copyright (c) 1991 Sun Wu and Udi Manber. All Rights Reserved.”
The upstream launcher runs `agrep -2 int InstructionCombining.cpp`; `-2`
selects a two-error search. No redistribution license is inferred. This
package is an independent implementation of the bounded approximate-substring
contract; it does not include copied upstream source or comments. The package
keeps the source's approximate-substring operation and error allowance while
using one in-memory record and a scalar count as its bounded ABI.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/agrep_approx_substring_count.c`](../../../c/a/agrep_approx_substring_count.c) |
| C3 | [`c3/a/agrep_approx_substring_count.c3`](../../../c3/a/agrep_approx_substring_count.c3) |
| C++ | [`cpp/a/agrep_approx_substring_count.cpp`](../../../cpp/a/agrep_approx_substring_count.cpp) |
| Elisa | [`elisa/a/agrep_approx_substring_count.elisa`](../../../elisa/a/agrep_approx_substring_count.elisa) |
| Nim | [`nim/a/agrep_approx_substring_count.nim`](../../../nim/a/agrep_approx_substring_count.nim) |
| Odin | [`odin/a/agrep_approx_substring_count.odin`](../../../odin/a/agrep_approx_substring_count.odin) |
| Rust | [`rust/a/agrep_approx_substring_count.rs`](../../../rust/a/agrep_approx_substring_count.rs) |
| V | [`v/a/agrep_approx_substring_count.v`](../../../v/a/agrep_approx_substring_count.v) |
| Zig | [`zig/a/agrep_approx_substring_count.zig`](../../../zig/a/agrep_approx_substring_count.zig) |

