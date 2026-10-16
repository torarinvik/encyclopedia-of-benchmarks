# XOR missing-number search

This benchmark ports the pinned Go `XorSearchMissingNumber` routine. Given an
array of `n` distinct values from `[0, n]`, it returns the only missing value.
The source initializes the accumulator to `n` and XORs each index and array
value in one pass.

## Contract

- Input is packed as `[n, value_0, ..., value_(n-1)]`, with `n` from 0 through
  255. The array must contain `n` distinct integers, each from 0 through `n`.
- The result is the missing value in `[0, n]`; for `n = 0`, the empty array
  returns 0.
- Invalid headers, truncated or extra values, out-of-range entries, and
  duplicate entries return `-1`. The input parser accepts up to 257 values so
  it can record a complete one-over-bound payload.
- The XOR scan uses O(n) time and O(1) auxiliary space. A fixed 256-entry
  validation table checks the packed input domain.

The independent oracle locates the missing value by set membership rather
than reproducing the source XOR recurrence. The workload covers both ends of
the range, arbitrary order, the maximum valid size, malformed arrays, and a
full one-over-bound input.

## Pinned source

The benchmark follows Go
[`xorsearch.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/binary/xorsearch.go)
at commit `5ba447ec5ff3d1213de65b92e726ee74c5d5cc19`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/x/xor_search_missing_number.c`](../../../c/x/xor_search_missing_number.c) |
| C3 | [`c3/x/xor_search_missing_number.c3`](../../../c3/x/xor_search_missing_number.c3) |
| C++ | [`cpp/x/xor_search_missing_number.cpp`](../../../cpp/x/xor_search_missing_number.cpp) |
| Elisa | [`elisa/x/xor_search_missing_number.elisa`](../../../elisa/x/xor_search_missing_number.elisa) |
| Nim | [`nim/x/xor_search_missing_number.nim`](../../../nim/x/xor_search_missing_number.nim) |
| Odin | [`odin/x/xor_search_missing_number.odin`](../../../odin/x/xor_search_missing_number.odin) |
| Rust | [`rust/x/xor_search_missing_number.rs`](../../../rust/x/xor_search_missing_number.rs) |
| V | [`v/x/xor_search_missing_number.v`](../../../v/x/xor_search_missing_number.v) |
| Zig | [`zig/x/xor_search_missing_number.zig`](../../../zig/x/xor_search_missing_number.zig) |

The workload is [`workload.json`](workload.json), and the oracle is
[`xor_search_missing_number_oracle.py`](../../xor_search_missing_number_oracle.py).
