# Quick Search

This package ports TheAlgorithms/Go's `Horspool` search as a first-match Quick Search variant. It compares each window from right to left, then chooses its next alignment from the text byte immediately after that window. That lookahead-byte shift is the distinguishing rule; pure Boyer–Moore–Horspool instead looks at the byte aligned with the end of the current window.

## Contract

- Input is `[text_length, pattern_length, text_bytes..., pattern_bytes...]` in the signed 64-bit array ABI. Each sequence is at most 255 bytes, the packed input has exactly `2 + text_length + pattern_length` values, and bytes are ASCII values 0 through 127.
- Return the first matching zero-based byte index. An empty pattern returns `0`; an absent pattern, a pattern longer than the text, or malformed input returns `-1`.
- The bounded ASCII input preserves the source's rune-index behavior as byte offsets. The source returns only the first match.
- The source initializes shifts to the pattern length for bytes in the text and then sets each pattern byte's distance to `pattern_length - index`, leaving the rightmost occurrence. This is the lookahead rule. For a byte absent from the pattern it shifts by `pattern_length` (the canonical Sunday rule often uses `pattern_length + 1`); the smaller source shift keeps the search conservative and avoids skipping candidate alignments.

## Relationship to other search packages

This is separate from [`boyer_moore_horspool`](../../b/boyer_moore_horspool/README.md), whose mismatch shift uses the byte at the end of the current window, and from [`boyer_moore_ag`](../../b/boyer_moore_ag/README.md), which keeps Apostolico–Giancarlo suffix memory and shifts from the mismatching byte. The Go source is named `horspool.go` and comments that it implements Boyer–Moore–Horspool, but its actual lookup at `text[pos + len(pattern)]` is the Quick Search/Sunday-style lookahead rule.

## Upstream source

- [Go `horspool.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/strings/horspool/horspool.go)

## Workload

[`workload.json`](workload.json) covers the empty pattern, hits after lookahead shifts, a fallback shift for a byte absent from the pattern, misses, embedded NUL, ASCII boundaries, and malformed packed inputs. Build with the `i64_array_scalar` ABI family and record with `benchmarks/run_i64_array_scalar.py`.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm quick_search --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/q/quick_search/rust/build.json
```
