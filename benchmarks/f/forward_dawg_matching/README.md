# Forward DAWG Matching

This package implements Forward DAWG Matching (FDM): build the pattern's
minimal suffix automaton, scan the text once from left to right, and follow
suffix links when the current state has no transition for the next symbol.
The state and a separate matched-factor length track the longest pattern
factor ending at each text position. Every position with matched length `m`
reports an occurrence, including overlaps.

## Bounded profile

The exported `forward_dawg_matching` function uses the `i64_array_scalar`
ABI. Its input is `[n,m,text[0..n),pattern[0..m)]`, with `n` from 0 through
4,096, `m` from 1 through 128, symbols from 0 through 3, and exact length
`2+n+m`. One trailing word is parseable but invalid. Invalid input returns
`-1`. The result packs `(match_count << 36) | (sum_of_offsets << 12) |
xor_of_offsets`. The workspace ceiling is 16,384 bytes for the staged
pattern and dense suffix-automaton tables; the text is read directly from
the validated input frame.

The algorithm builds the pattern's suffix automaton in linear time for this
fixed four-symbol alphabet. It then inspects exactly one text symbol per
position while carrying transitions through suffix links. This is distinct
from local Backward Nondeterministic DAWG Matching, which simulates a
bit-parallel automaton right-to-left for each candidate window, and from
suffix-automaton indexing packages, which answer index queries instead of
searching a text stream for all pattern occurrences.

The algorithm description and textbook pseudocode are in Chapter 13 of
Charras and Lecroq's [Forward DAWG Matching chapter](https://igm.univ-mlv.fr/~lecroq/string/fdm.html)
and the [ESMAJ string-matching reference](https://www-igm.univ-mlv.fr/~lecroq/string/string.pdf).
The chapter cites Crochemore and Rytter, *Text Algorithms* (Oxford University
Press, 1994). Only mathematical descriptions were consulted; the ports,
bounded contract, and workload are independently written. See
[RIGHTS.md](RIGHTS.md).

[`primary_oracle.py`](primary_oracle.py) uses sparse transition maps and the
suffix-link scan. [`independent_oracle.py`](independent_oracle.py) checks
every possible alignment directly. [`workload.json`](workload.json) covers
overlaps, suffix-link fallback, one-symbol patterns, and invalid frames.
