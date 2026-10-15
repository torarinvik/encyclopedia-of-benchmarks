# Alternative list arrange

This benchmark implements the Python `alternative_list_arrange` source: take one item from the first input, then one from the second input, preserving the order within both inputs. When one input ends, append the remaining items from the other input. Empty inputs are valid.

Source: [TheAlgorithms/Python `alternative_list_arrange.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/other/alternative_list_arrange.py).

## Contract

The input is a packed signed 64-bit array `[first_count, first values..., second_count, second values...]`. Each count is from 0 through 64, and values are signed 64-bit integers. The total input length must be exact. The output is the interleaved sequence encoded as little-endian signed 64-bit values. The function returns the number of output values, `-1` for malformed input, or `-2` when the output buffer is too small.

The source is generic over element types; this benchmark uses signed integers while preserving its ordering and tail behavior.

[`workload.json`](workload.json) covers unequal lengths in both directions, either empty input, and two empty inputs.

| Language | Source |
| --- | --- |
| C | [`c/a/alternative_list_arrange.c`](../../../c/a/alternative_list_arrange.c) |
| C3 | [`c3/a/alternative_list_arrange.c3`](../../../c3/a/alternative_list_arrange.c3) |
| C++ | [`cpp/a/alternative_list_arrange.cpp`](../../../cpp/a/alternative_list_arrange.cpp) |
| Elisa | [`elisa/a/alternative_list_arrange.elisa`](../../../elisa/a/alternative_list_arrange.elisa) |
| Nim | [`nim/a/alternative_list_arrange.nim`](../../../nim/a/alternative_list_arrange.nim) |
| Odin | [`odin/a/alternative_list_arrange.odin`](../../../odin/a/alternative_list_arrange.odin) |
| Rust | [`rust/a/alternative_list_arrange.rs`](../../../rust/a/alternative_list_arrange.rs) |
| V | [`v/a/alternative_list_arrange.v`](../../../v/a/alternative_list_arrange.v) |
| Zig | [`zig/a/alternative_list_arrange.zig`](../../../zig/a/alternative_list_arrange.zig) |
