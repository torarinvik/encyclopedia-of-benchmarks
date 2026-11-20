# Glushkov bit-parallel regular-expression search

This package searches every text prefix for a nonempty matching suffix using a
Glushkov position automaton. Its states are the regex symbol positions plus the
initial state. The epsilon-free transition relation is represented as a
bit-parallel subset transition table.

## Contract

The exported `glushkov_bit_parallel_regex_search` function uses the
`i64_array_bytes_output` ABI. Input is
`[text_length, pattern_length, text_bytes..., pattern_bytes...]`.

- Text length is `0..24`; pattern length is `1..32`.
- Every text and pattern byte is in `1..127`.
- The grammar is `regex := concat ('|' concat)*`,
  `concat := repeat+`, `repeat := atom '*'?`, and
  `atom := 'a' | 'b' | 'c' | '.' | '(' regex ')'`.
- `.` matches any input byte. `*` applies to one atom. Empty alternatives,
  empty groups, repeated postfix stars, and other syntax are invalid.
- A pattern may have at most eight consuming symbol positions.
- The packed array has exactly `2 + text_length + pattern_length` values and at
  most 58 values.

The output has one byte per text position. Byte `i` is 1 exactly when some
nonempty substring ending at position `i` matches the pattern, and 0 otherwise.
Empty matches are deliberately not reported. The function returns the number
of output bytes written, `-1` for invalid input, and `-2` for a null output
pointer or insufficient capacity. An empty text succeeds with result 0 and
requires no output pointer. Errors leave output untouched. Maximum output is
24 bytes; fixed algorithm workspace, including bounded parser state, is at
most 8,192 bytes.

The parser builds a bounded syntax tree, computes First/Last/Follow position
sets, then evaluates the position automaton. For each possible current-state
mask `S`, `T[S]` is the union of Follow sets of its states. Each byte has a
matching-position mask `B[c]`; the transition is `T[S] & B[c]`. State zero is
reintroduced by the initial-state Follow set and byte masks, which permits a
match to begin at every text position. For at most `m=9` states, pattern
length `p`, and text length `n`, the cost is `O(p + 2^m + 128m + n)` time and
`O(2^m + 128 + m + p)` workspace.

## Distinction and source

The local `mcnaughton_yamada_thompson` profile builds and simulates a Thompson
epsilon-NFA. `slre` provides its own source-compatible unanchored regex search,
and `regex_match` uses recursive backtracking for `.` and `*`. This profile
uses the epsilon-free Glushkov position automaton and precomputed bit-parallel
subset transitions; its state representation and transition procedure are
materially different.

Chapter 340, “Regular Expression Matching,” of the *Encyclopedia of
Algorithms*, second edition, describes the Glushkov-McNaughton-Yamada
epsilon-free automaton and bit-parallel transition-table representation. The
primary reference below gives the position automaton and bit-parallel search
construction. The implementation is a bounded clean-room realization of that
algorithmic description; no source code, book prose, examples, or figures are
reproduced. See [RIGHTS.md](RIGHTS.md).

[`workload.json`](workload.json) supplies the bounded fixture contract.
[`primary_oracle.py`](primary_oracle.py) evaluates the same position-set
construction; [`independent_oracle.py`](independent_oracle.py) checks suffix
matches by direct recursive AST evaluation. [`verify_workload.py`](verify_workload.py)
checks only package metadata and source inventory; it does not execute ports.
The ten source paths are listed in [`INVENTORY.md`](INVENTORY.md).
