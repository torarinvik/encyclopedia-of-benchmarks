# Boyer–Moore with Apostolico–Giancarlo suffix memory

This benchmark ports the Go `BoyerMoore` function as an all-match search. It builds a bad-character distance table for pattern bytes before the final byte, precomputes matching-suffix lengths keyed by each available shift, and reuses those suffix lengths on later alignments. On a mismatch, it shifts using the mismatching text byte; on a match, it advances one position so overlaps remain visible.

## Contract

- Input is `[text_length, pattern_length, text_bytes..., pattern_bytes...]`, with each length from 0 through 255 and exactly `2 + text_length + pattern_length` values.
- Pattern length must be at least 1. The Go source does not advance its outer loop for an empty pattern; rejecting it avoids that nontermination. Text and pattern bytes are ASCII values 0 through 127.
- Output contains all zero-based match positions in ascending order, one position byte per match. A pattern longer than the text returns zero matches. Invalid packed input returns `-1`; insufficient output capacity returns `-2`.
- The text bound keeps every result position within one byte. The local ports use bounded scratch storage for up to 255 nonempty-pattern matches.

## Relationship to the other search packages

This is distinct from pure `boyer_moore_horspool`: it keeps Apostolico–Giancarlo suffix-skip state and uses the mismatching byte to select the distance. It is also distinct from `boyer_moore_search`, which uses only the rightmost bad-character occurrence, and from full `boyer_moore`, which combines bad-character and strong good-suffix shifts.

The pinned Go source returns every match in `[]int`. The benchmark keeps that result shape and normalizes the inputs to bounded ASCII bytes.

## Reviewed source

- [Go `boyermoore.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/strings/search/boyermoore.go)

## Workload

[`workload.json`](workload.json) covers no-match cases, all-match output, overlapping results, empty text, a rejected empty pattern, embedded NUL, ASCII boundaries, and malformed packed data. The nine ports use the shared `i64_array_bytes_output` ABI.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm boyer_moore_ag --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/b/boyer_moore_ag/rust/build.json
```
