# Boyer–Moore–Horspool search

Find every pattern occurrence with the Horspool bad-character shift. The shift table uses all pattern bytes except the final byte; a mismatch compares the pattern from right to left, then shifts according to the text byte aligned with the end of the current window. Matches advance one byte so overlaps are reported.

## Contract

- Input is `[text_length, pattern_length, text_bytes..., pattern_bytes...]`. Each sequence is at most 255 bytes, and the packed array must contain exactly `2 + text_length + pattern_length` values.
- Text and pattern values are ASCII bytes from 0 through 127. Empty text and pattern are valid.
- Output contains every zero-based match position in ascending order, one position byte per match. The function returns the number of matches. Empty patterns match boundaries `0` through `text_length`; a pattern longer than the text has no matches.
- Invalid packed input returns `-1`; insufficient output capacity returns `-2`. A text bound of 255 keeps every output position, including boundary 255, in one byte.
- Preprocessing takes `O(m + σ)` time and `O(σ)` space for the 128-byte ASCII alphabet. Search is `O(nm)` in the worst case and typically skips multiple bytes per window.

## Relationship to the other Boyer–Moore packages

This shift rule is distinct from both existing packages. `boyer_moore_search` uses the mismatching text byte and its rightmost pattern occurrence; full `boyer_moore` combines that rule with a good-suffix shift. Horspool instead bases each shift on the byte at the end of the current text window and has no good-suffix table.

The Python source is a direct all-match Horspool implementation. The two C++ `horspool.cpp` sources use the same window-end shift and return a presence boolean, which this contract expands to all match positions. Ruby's `BadMatchTable` includes the last pattern byte (which gives a zero shift) and looks up the mismatching byte rather than the window-end byte, so this port follows the intended Horspool rule and avoids that source defect.

The Go `boyermoore.go` source adds Apostolico–Giancarlo suffix-skip state and looks up the mismatching byte; it is a separate variant. The Go `horspool.go` candidate looks up the byte just after the current window, which is a Quick Search/Sunday-style lookahead shift rather than Horspool's window-end shift; it also returns only the first match.

## Reviewed sources

- [Python `boyer_moore_horspool.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/boyer_moore_horspool.py)
- [Ruby `boyer_moore_horspool_search.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/strings/boyer_moore_horspool_search.rb)
- [C++ `horspool.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/strings/horspool.cpp) and [C++-Plus-Plus-1 `horspool.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/strings/horspool.cpp)
- [Go `horspool.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/strings/horspool/horspool.go)
- [Go `boyermoore.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/strings/search/boyermoore.go)
- [Existing bad-character-only Boyer–Moore](../boyer_moore_search/README.md)
- [Existing full Boyer–Moore](../boyer_moore/README.md)

## Workload

[`workload.json`](workload.json) covers empty patterns, overlapping matches, source examples, embedded NUL, ASCII boundaries, absent matches, and malformed packed input. The nine ports use the shared `i64_array_bytes_output` ABI.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm boyer_moore_horspool --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/b/boyer_moore_horspool/rust/build.json
```
