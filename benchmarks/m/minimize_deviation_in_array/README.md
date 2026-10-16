# Minimize deviation in an array

The pinned Python routine maps each odd value to twice itself, places the values in a max heap, and repeatedly halves the current maximum while it remains even. It tracks the smallest value seen and minimizes the current maximum-minus-minimum deviation.

## Contract

Input is `[count, values...]` with 1 through 64 positive values, each at most 1,000,000. Output is the minimum attainable `max(values) - min(values)` under the source operations: divide even values by two, or double odd values. Invalid input returns `-1`.

The bounds keep doubled values and heap arithmetic safely within signed 64-bit range. The implementation preserves the source's greedy max-heap loop.

See [`workload.json`](workload.json) and the runtime [oracle](../../minimize_deviation_in_array_oracle.py). Pinned source: [TheAlgorithms/Python `minimize_deviation_in_array.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/greedy_methods/minimize_deviation_in_array.py).

| Language | Port |
|---|---|
| C | [`c/m/minimize_deviation_in_array.c`](../../../c/m/minimize_deviation_in_array.c) |
| C3 | [`c3/m/minimize_deviation_in_array.c3`](../../../c3/m/minimize_deviation_in_array.c3) |
| C++ | [`cpp/m/minimize_deviation_in_array.cpp`](../../../cpp/m/minimize_deviation_in_array.cpp) |
| Elisa | [`elisa/m/minimize_deviation_in_array.elisa`](../../../elisa/m/minimize_deviation_in_array.elisa) |
| Nim | [`nim/m/minimize_deviation_in_array.nim`](../../../nim/m/minimize_deviation_in_array.nim) |
| Odin | [`odin/m/minimize_deviation_in_array.odin`](../../../odin/m/minimize_deviation_in_array.odin) |
| Rust | [`rust/m/minimize_deviation_in_array.rs`](../../../rust/m/minimize_deviation_in_array.rs) |
| V | [`v/m/minimize_deviation_in_array.v`](../../../v/m/minimize_deviation_in_array.v) |
| Zig | [`zig/m/minimize_deviation_in_array.zig`](../../../zig/m/minimize_deviation_in_array.zig) |
