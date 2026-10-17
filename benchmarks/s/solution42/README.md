# Project Euler 42 word counter (`solution42`)

This benchmark preserves the pinned Python solution's fixed `words.txt`
fixture and its first-line-only file read. To make the input repeatable across
the nine language ports, the benchmark adapter passes file bytes as an i64
array; implementations process that byte array as the file contents.

## Contract

- ABI: `i64_array_scalar`.
- Input is the raw file contents as one signed 64-bit array element per ASCII
  byte. The bounded domain is 0 through 16,384 bytes, with every value in
  `0..127`. There is no length prefix; the array length is the file byte
  length.
- The source opens the fixture in Python text mode, so `readline()` stops at
  LF, CRLF, or a lone CR. It strips `\r` and `\n` from the ends of that line,
  splits on commas, strips double quote characters from each token's ends, and
  scores each remaining character as `ord(character) - 64`. Thus uppercase A
  scores 1. It counts each token whose score is one of `T_n = n(n+1)/2` for
  `n = 1..100`; duplicate words count independently.
- Only the first line is processed. Bytes after the first LF, CRLF, or lone CR
  line terminator are ignored, matching text-mode `readline()` in the pinned
  source. Empty input behaves
  like an empty first line and returns zero. The scalar ABI passes a null
  pointer for length zero; `(NULL, 0)` is valid and means an empty file. A null
  pointer with positive length is invalid.
- Return the count as an i64 scalar. Input longer than 16,384 bytes, a null
  pointer with positive length, or a value outside the ASCII byte range
  returns `-1`.

The pinned fixture is copied to [`words.txt`](words.txt) and embedded in the
`pinned_words_fixture` workload case. The source example returns 162. A small
two-line fixture makes first-line-only behavior explicit.

## Pinned source

- [`solution42.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_042/solution42.py), commit `e1a2a8b016001309a73d5fec4818c35cca139795`, `solution()`.
- [`words.txt`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_042/words.txt) at the same commit.

The workload and independent oracle are [`workload.json`](workload.json) and
[`benchmarks/solution42_oracle.py`](../../solution42_oracle.py).
