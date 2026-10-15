# Z algorithm search

This benchmark finds every occurrence of an ASCII pattern in an ASCII text with the Z algorithm. It is distinct from the existing Knuth–Morris–Pratt, Rabin–Karp, and single-match search benchmarks because it returns all matching positions and uses ASCII case-insensitive matching.

## Contract

- Input is `[text_length, pattern_length, text_bytes..., pattern_bytes...]` in the signed 64-bit array ABI. Each sequence has 0 through 2,047 bytes, and each byte is in `[0, 127]`. The packed input must contain exactly `2 + text_length + pattern_length` values.
- Match ASCII letters without regard to case. Other ASCII bytes compare exactly. Include overlapping matches and return positions in ascending order.
- Write each matching position as an unsigned 32-bit little-endian integer. Positions are one-based to follow the R function's returned position convention. Return the number of positions written, `-1` for malformed input, and `-2` if the output buffer is too small. A pattern of length zero matches every text boundary, at positions `1` through `text_length + 1`.
- The implementation uses the Z algorithm over the pattern, a separator value outside the accepted byte range, and the text. The maximum concatenated sequence has 4,095 elements, so all storage is statically bounded.

## Upstream semantics

The benchmark follows the pinned [TheAlgorithms R source](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/searches/z.algorithm.search.r), which constructs `pattern + "$" + text` and returns positions adjusted to the text. Its interactive script lowercases both strings before calling the function; the function itself is case-sensitive. The source selects `Z > pattern_length`, which omits ordinary exact matches where the Z value equals the pattern length. Its literal `$` separator can also collide with input data. This package repairs those two defects to implement the source's stated all-occurrences search: it accepts `Z >= pattern_length` and uses an out-of-domain separator. The portable contract uses ASCII case folding to preserve the script's interactive behavior and defines empty-pattern and output-buffer behavior explicitly.

Other TheAlgorithms implementations expose related but different Z operations: [Rust's `match_pattern`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74a4c939ec5163648458a8c2b46fd4c/src/string/z_algorithm.rs) returns zero-based indices, [C++'s `find_pat_in_text`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/strings/z_function.cpp) returns zero-based indices, and Python's `find_pattern` returns only a count. No existing Z-function benchmark package overlaps this all-position, case-insensitive contract.

## Workload and build

[`workload.json`](workload.json) covers empty patterns, overlapping and repeated matches, ASCII case folding, `$` bytes, boundary bytes, misses, malformed inputs, and the maximum packed input length. Build with the `i64_array_bytes_output` ABI family and record with `benchmarks/run_i64_array_bytes_output.py`.

The nine implementations are in `c/z/z_algorithm_search.c`, `c3/z/z_algorithm_search.c3`, `cpp/z/z_algorithm_search.cpp`, `elisa/z/z_algorithm_search.elisa`, `nim/z/z_algorithm_search.nim`, `odin/z/z_algorithm_search.odin`, `rust/z/z_algorithm_search.rs`, `v/z/z_algorithm_search.v`, and `zig/z/z_algorithm_search.zig`.
