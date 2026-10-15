# Is Arithmetic Series

Check whether a nonempty integer sequence has a constant consecutive difference.

## Contract

- Uses the `i64_array_scalar_call` ABI with one signed 64-bit integer array.
- Accepts 1 through 64 signed integer values, each in [-1,000,000, 1,000,000]. The result is 1 for arithmetic sequences and 0 otherwise.
- The source returns true for a singleton and for lists whose consecutive differences all equal the first difference. It raises on empty/non-list input; invalid lengths and values map to -1 in this ABI.
- The result follows the source operation: `1 if all consecutive differences equal the first difference, else 0`.

## Source semantics

This follows [TheAlgorithms Python `arithmetic.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/series/arithmetic.py). That file also contains the separately benchmarked routine `arithmetic_mean`. These ports implement the bounded integer-list subset.

## Workload

[`workload.json`](workload.json) covers source-like values, singleton behavior, signed values, and invalid lengths or elements.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/is_arithmetic_series.c`](../../../c/i/is_arithmetic_series.c) |
| C3 | [`c3/a/is_arithmetic_series.c3`](../../../c3/i/is_arithmetic_series.c3) |
| CPP | [`cpp/a/is_arithmetic_series.cpp`](../../../cpp/i/is_arithmetic_series.cpp) |
| ELISA | [`elisa/a/is_arithmetic_series.elisa`](../../../elisa/i/is_arithmetic_series.elisa) |
| NIM | [`nim/a/is_arithmetic_series.nim`](../../../nim/i/is_arithmetic_series.nim) |
| ODIN | [`odin/a/is_arithmetic_series.odin`](../../../odin/i/is_arithmetic_series.odin) |
| RUST | [`rust/a/is_arithmetic_series.rs`](../../../rust/i/is_arithmetic_series.rs) |
| V | [`v/a/is_arithmetic_series.v`](../../../v/i/is_arithmetic_series.v) |
| ZIG | [`zig/a/is_arithmetic_series.zig`](../../../zig/i/is_arithmetic_series.zig) |
