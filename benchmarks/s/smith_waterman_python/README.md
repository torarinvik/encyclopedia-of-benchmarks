# Smith–Waterman Python Matrix and Traceback

This package preserves the pinned Python `smith_waterman` score matrix and
`traceback` functions together. Its matrix is case-insensitive. The traceback
uses the first row-major maximum and the default scores `1/-1/-2`, even when
the matrix was built with custom scores; it keeps walking while both indices
are positive, including after reaching a zero cell. These details distinguish
it from both the Java scalar API and the Rust traceback API.

## Contract

- Input is `[query_length, subject_length, match, mismatch, gap,
  query_ascii..., subject_ascii...]`. Each sequence has 0 to 16 ASCII letters
  or hyphens. Scores are bounded to match `1..5`, mismatch `-5..-1`, and gap
  `-5..-1`. The packed length is exactly `5 + query_length + subject_length`.
- Uppercase ASCII letters before scoring. A pair containing `-` receives the
  gap score. The local-alignment matrix uses zero boundaries and
  `max(0, diagonal, above+gap, left+gap)`.
- Trace back from the first row-major maximum. Return empty bytes when that
  cell is on the top or left boundary. Otherwise compare against the pinned
  default scoring (`1/-1/-2`), prefer diagonal then above, and use left when
  neither equality holds. Continue until either index reaches zero; do not
  stop at a zero-valued cell.
- Output bytes are `rows:u32le, columns:u32le, row-major scores:i32le,
  traceback_length:u32le, traceback_ascii`. The traceback text contains two
  alignment rows separated by one newline. Success returns the byte count;
  malformed input returns `-1`; null or short output returns `-2` without
  writes. Maximum output is 1,233 bytes.

The reference is the pinned TheAlgorithms/Python
[`smith_waterman.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/smith_waterman.py)
at commit `e1a2a8b016001309a73d5fec4818c35cca139795`.

[`workload.json`](workload.json) includes lowercase input, zero-cell traceback,
empty sequences, malformed framing, invalid characters and output-capacity
errors. Build with `i64_array_bytes_output` and record with
`benchmarks/run_i64_array_bytes_output.py`.

## Ports

- [C](../../../c/s/smith_waterman_python.c)
- [C++](../../../cpp/s/smith_waterman_python.cpp)
- [C3](../../../c3/s/smith_waterman_python.c3)
- [Rust](../../../rust/s/smith_waterman_python.rs)
- [Elisa](../../../elisa/s/smith_waterman_python.elisa)
- [Nim](../../../nim/s/smith_waterman_python.nim)
- [Odin](../../../odin/s/smith_waterman_python.odin)
- [V](../../../v/s/smith_waterman_python.v)
- [Zig](../../../zig/s/smith_waterman_python.zig)
