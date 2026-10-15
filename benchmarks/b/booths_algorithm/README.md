# Booth's algorithm for minimal string rotation

Find the lexicographically smallest rotation of a string with Booth's linear-time failure-table algorithm. This candidate is the string rotation algorithm; it is separate from Booth's multiplication algorithm.

## Contract

The `i64_array_bytes_output` input contains one signed 64-bit ASCII code point per character. Inputs contain from 1 through 256 values, each in `[0, 127]`. The output is the lexicographically smallest cyclic rotation, with each input code point emitted as one byte. Invalid input returns `-1`; a null output pointer or insufficient capacity returns `-2`.

## Workload

[`workload.json`](workload.json) includes the pinned source's examples, single-character and periodic strings, an embedded NUL byte, empty input, non-ASCII input, and short capacity.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/booths_algorithm.c`](../../../c/b/booths_algorithm.c) |
| C3 | [`c3/b/booths_algorithm.c3`](../../../c3/b/booths_algorithm.c3) |
| C++ | [`cpp/b/booths_algorithm.cpp`](../../../cpp/b/booths_algorithm.cpp) |
| Elisa | [`elisa/b/booths_algorithm.elisa`](../../../elisa/b/booths_algorithm.elisa) |
| Nim | [`nim/b/booths_algorithm.nim`](../../../nim/b/booths_algorithm.nim) |
| Odin | [`odin/b/booths_algorithm.odin`](../../../odin/b/booths_algorithm.odin) |
| Rust | [`rust/b/booths_algorithm.rs`](../../../rust/b/booths_algorithm.rs) |
| V | [`v/b/booths_algorithm.v`](../../../v/b/booths_algorithm.v) |
| Zig | [`zig/b/booths_algorithm.zig`](../../../zig/b/booths_algorithm.zig) |

## Pinned source

- Python [`booths_algorithm.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/booths_algorithm.py)
