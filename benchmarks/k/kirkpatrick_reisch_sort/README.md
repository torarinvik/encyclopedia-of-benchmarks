# Kirkpatrick–Reisch Sort

This benchmark measures the pinned Python implementation's deterministic block sort and min-heap merge. The random number generator imported by the source is used only by its demo entry point.

## Contract

Input is a signed-i64 array `[n, value_0, ..., value_(n-1)]`. `n` is 0 through 256, each value is any signed 64-bit integer, and input length must equal `n + 1`. The maximum valid input is 257 words; 258 words are parseable for a trailing-data check.

For `n > 1`, set `block_size = floor(sqrt(n))`, split the input into contiguous blocks of that size (the final block may be shorter), sort each block in ascending order, and merge the blocks with a min-heap. For `n` equal to 0 or 1, return the input sequence unchanged. Duplicate values are preserved, and the input is not modified.

Output is the ascending sequence as little-endian signed-i64 words. It contains at most 256 elements or 2048 bytes. A valid empty input succeeds with zero output bytes when the output pointer is non-null. Invalid framing, count, or values return `-1` before output checks. A null output pointer or insufficient byte capacity returns `-2`, including for an empty result; errors write no bytes.

## Pinned source

- Python [`kirkpatrick_reisch_sort.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/kirkpatrick_reisch_sort.py), function `kirkpatrick_reisch_sort`, commit `e1a2a8b016001309a73d5fec4818c35cca139795`.

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Oracle: [`benchmarks/kirkpatrick_reisch_sort_oracle.py`](../../kirkpatrick_reisch_sort_oracle.py)

## Language ports

| Language | Port |
|---|---|
| C | [`c/k/kirkpatrick_reisch_sort.c`](../../../c/k/kirkpatrick_reisch_sort.c) |
| C3 | [`c3/k/kirkpatrick_reisch_sort.c3`](../../../c3/k/kirkpatrick_reisch_sort.c3) |
| C++ | [`cpp/k/kirkpatrick_reisch_sort.cpp`](../../../cpp/k/kirkpatrick_reisch_sort.cpp) |
| Elisa | [`elisa/k/kirkpatrick_reisch_sort.elisa`](../../../elisa/k/kirkpatrick_reisch_sort.elisa) |
| Nim | [`nim/k/kirkpatrick_reisch_sort.nim`](../../../nim/k/kirkpatrick_reisch_sort.nim) |
| Odin | [`odin/k/kirkpatrick_reisch_sort.odin`](../../../odin/k/kirkpatrick_reisch_sort.odin) |
| Rust | [`rust/k/kirkpatrick_reisch_sort.rs`](../../../rust/k/kirkpatrick_reisch_sort.rs) |
| V | [`v/k/kirkpatrick_reisch_sort.v`](../../../v/k/kirkpatrick_reisch_sort.v) |
| Zig | [`zig/k/kirkpatrick_reisch_sort.zig`](../../../zig/k/kirkpatrick_reisch_sort.zig) |
