# Mixed-keyword cipher

This benchmark follows the pinned Python `mixed_keyword` function with its
default `A` through `Z` alphabet. It preserves the source's first-seen keyword
ordering, row construction, and column-first substitution mapping.

## Contract

- ABI: `i64_array_bytes_output`.
- Input is `[keyword_length, keyword_ascii..., plaintext_length,
  plaintext_ascii...]`. Keyword length is 1 through 64; plaintext length is 0
  through 512. Every character value must be ASCII 0 through 127, and the input
  must contain exactly `2 + keyword_length + plaintext_length` signed-i64
  words (at most 578).
- The key must contain at least one ASCII letter after ASCII lowercase letters
  are uppercased. Other ASCII key characters are ignored, as in the source.
  The substitution key consists of unique letters in first-seen order followed
  by the unused letters from `A` through `Z`.
- The shifted letters are split into rows whose width is the number of unique
  key letters. The source maps `A` through `Z` by visiting columns first and
  rows second. ASCII lowercase plaintext letters are uppercased before
  substitution; other ASCII plaintext characters pass through unchanged.
- Invalid input, a null input pointer, or a key with no ASCII letters returns
  `-1` before output-buffer checks. Successful calls return the number of
  output bytes. A null output pointer or insufficient capacity returns `-2`
  without writing, including a null output pointer for empty plaintext.
- Maximum output is 512 bytes. The independent oracle is
  [`mixed_keyword_cypher_oracle.py`](../../mixed_keyword_cypher_oracle.py).

The workload includes the pinned `college` / `UNIVERSITY` example, duplicate
and ignored key characters, lowercase and pass-through plaintext, one-letter
keys, ASCII control characters, invalid keys and characters, framing errors,
and maximum input/output coverage.

## Pinned source

[TheAlgorithms/Python `mixed_keyword_cypher.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/mixed_keyword_cypher.py)
at commit `e1a2a8b016001309a73d5fec4818c35cca139795`.

## Language ports

| Language | Port |
| --- | --- |
| C | [c/m/mixed_keyword_cypher.c](../../../c/m/mixed_keyword_cypher.c) |
| C3 | [c3/m/mixed_keyword_cypher.c3](../../../c3/m/mixed_keyword_cypher.c3) |
| C++ | [cpp/m/mixed_keyword_cypher.cpp](../../../cpp/m/mixed_keyword_cypher.cpp) |
| Elisa | [elisa/m/mixed_keyword_cypher.elisa](../../../elisa/m/mixed_keyword_cypher.elisa) |
| Nim | [nim/m/mixed_keyword_cypher.nim](../../../nim/m/mixed_keyword_cypher.nim) |
| Odin | [odin/m/mixed_keyword_cypher.odin](../../../odin/m/mixed_keyword_cypher.odin) |
| Rust | [rust/m/mixed_keyword_cypher.rs](../../../rust/m/mixed_keyword_cypher.rs) |
| V | [v/m/mixed_keyword_cypher.v](../../../v/m/mixed_keyword_cypher.v) |
| Zig | [zig/m/mixed_keyword_cypher.zig](../../../zig/m/mixed_keyword_cypher.zig) |
