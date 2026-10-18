# Smith–Waterman Rust Matrix and Traceback

This package preserves the pinned Rust `smith_waterman` matrix API and its
separate `traceback` API together. It uppercases both sequences before scoring
and emits the full matrix. Its traceback uses the first row-major maximum,
honors the supplied match/mismatch/gap scores, and stops when the current score
reaches zero. Python's package has a different traceback contract.

## Contract

- Input is `[query_length, subject_length, match, mismatch, gap,
  query_ascii..., subject_ascii...]`. Each sequence has 0 to 16 ASCII letters
  or hyphens. Scores are bounded to match `1..5`, mismatch `-5..-1`, and gap
  `-5..-1`. The packed length is exactly `5 + query_length + subject_length`.
- Uppercase ASCII letters before scoring. A pair containing `-` receives the
  supplied gap score. Initialize zero boundaries and use the local recurrence
  `max(0, diagonal, above+gap, left+gap)`.
- Trace back from the first row-major maximum. Return empty bytes if it is not
  positive. Otherwise prefer diagonal then above, and use left when neither
  equality holds; stop once either index is zero or the current matrix score
  is zero.
- Output bytes are `rows:u32le, columns:u32le, row-major scores:i32le,
  traceback_length:u32le, traceback_ascii`. The traceback text contains the
  two aligned rows separated by one newline. Success returns the byte count;
  malformed input returns `-1`; null or short output returns `-2` without
  writes. Maximum output is 1,233 bytes.

The reference is the pinned TheAlgorithms/Rust
[`smith_waterman.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/dynamic_programming/smith_waterman.rs)
at commit `fed66cb0c74c4a939ec5163648458a8c2b46fd4c`.

[`workload.json`](workload.json) covers case-insensitive input, the zero-score
traceback boundary, custom scoring, empty sequences and output errors. Build
with `i64_array_bytes_output` and record with
`benchmarks/run_i64_array_bytes_output.py`.
