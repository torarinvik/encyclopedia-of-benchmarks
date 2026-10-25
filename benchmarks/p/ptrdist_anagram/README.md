# Ptrdist Anagram Decomposition Search

This benchmark ports the distinctive search core of Raymond Chen's 1991
Ptrdist `anagram` program. It finds ways to decompose a phrase into dictionary
words, reusing words when needed. At each recursive step it pivots on the
rarest still-unused letter, tries only candidates containing that letter,
checks word fit with packed per-letter fields, and defers candidates that do
not contain the pivot. This is a multiword decomposition search, not the
single-word frequency comparison or dictionary lookup performed by the local
[`valid_anagram`](../../v/valid_anagram/README.md),
[`check_anagram`](../../c/check_anagram/README.md),
[`detect_anagrams`](../../d/detect_anagrams/README.md), or
[`anagram_dictionary_search`](../../a/anagram_dictionary_search/README.md)
benchmarks.

## Contract

The `i64_array_scalar` input is
`[phrase_length, phrase_ascii..., dictionary_count, word_length, word_ascii..., ...]`.
The phrase contains 1–16 ASCII letters, and the dictionary contains 0–12
words, each containing 1–16 ASCII letters. Uppercase letters are normalized to
lowercase. Inputs are consumed in order; words may be reused in a solution.
The result is the number of complete decompositions found by the search.

The launcher invokes `anagram words 2`, so the source's minimum word length
is two. It admits a candidate when it has at least two letters and leaves at
least two phrase letters, or when it is the whole phrase. The bounded profile
retains that candidate filter. One-letter entries are accepted in the input
because the source admits an exact whole-phrase match even when the phrase is
shorter than the configured minimum. Invalid array framing or nonletter bytes
return `-1`. The custom structured contract requires ASCII letters directly;
the original line-oriented program ignored nonletters while processing its
phrases and dictionary.

The upstream packs letter counts into dynamically sized fields in one or more
machine words, subtracts each candidate's packed counts from the remaining
phrase, and checks the per-field sign bits for underflow. The bounded
16-letter profile fits those fields in one portable 64-bit word. The original
program prints a periodic sample of found decompositions; this adapted pure
function returns the full decomposition count instead, while retaining the
rare-letter depth-first search and its candidate deferral behavior. The
independent Python oracle uses letter-frequency maps rather than packed
bitfields.

## Provenance and rights

Pinned source: [`lac-dcc/Benchmarks` `Ptrdist/anagram` at
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Ptrdist/anagram).
The launcher is `anagram words 2` with phrases read from `input.OUT`. The
source header states that it is Copyright 1991 by Raymond Chen and may be
freely distributed provided all alterations to the original are clearly
indicated as such. Each port below reproduces that notice and identifies the
changes made for this bounded benchmark interface. The upstream `words`
dictionary is not redistributed; each workload supplies its own small word
list.

## Language ports

| Language | Source |
|---|---|
| C | [`c/p/ptrdist_anagram.c`](../../../c/p/ptrdist_anagram.c) |
| C3 | [`c3/p/ptrdist_anagram.c3`](../../../c3/p/ptrdist_anagram.c3) |
| C++ | [`cpp/p/ptrdist_anagram.cpp`](../../../cpp/p/ptrdist_anagram.cpp) |
| Elisa | [`elisa/p/ptrdist_anagram.elisa`](../../../elisa/p/ptrdist_anagram.elisa) |
| Nim | [`nim/p/ptrdist_anagram.nim`](../../../nim/p/ptrdist_anagram.nim) |
| Odin | [`odin/p/ptrdist_anagram.odin`](../../../odin/p/ptrdist_anagram.odin) |
| Rust | [`rust/p/ptrdist_anagram.rs`](../../../rust/p/ptrdist_anagram.rs) |
| V | [`v/p/ptrdist_anagram.v`](../../../v/p/ptrdist_anagram.v) |
| Zig | [`zig/p/ptrdist_anagram.zig`](../../../zig/p/ptrdist_anagram.zig) |

Independent oracle: [`ptrdist_anagram_oracle.py`](../../ptrdist_anagram_oracle.py).

The original source notice is reproduced here and in each port:

> Anagram program by Raymond Chen,
> inspired by a similar program by Brian Scearce
>
> This program is Copyright 1991 by Raymond Chen.
> (rjc@math.princeton.edu)
>
> This program may be freely distributed provided all alterations
> to the original are clearly indicated as such.
