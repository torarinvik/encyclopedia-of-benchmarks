# Double-Ended Selection Sort

This benchmark ports the pinned Python `merge_sort(collection)` entry point from `sorts/unknown_sort.py`. Despite its function name and docstring, the implementation is not merge sort: it repeatedly extracts the current minimum and maximum into separate endpoint buffers. The nine ports preserve that double-ended selection procedure and its quadratic work.

## Contract

- Input is an array of at most 256 signed i64 values. Empty and singleton arrays are valid. The source accepts comparable Python objects; this benchmark restricts values to signed i64 integers.
- Each pass selects the first minimum and first maximum, appends them to separate buffers, removes the first minimum, then removes the first matching maximum from the remaining values. It reverses the maximum buffer and returns `minima + optional middle + reversed maxima`.
- Output is the sorted signed-i64 sequence encoded as little-endian words, without a length header. Malformed input returns `-1`; insufficient capacity or a null output pointer returns `-2`.

The independent oracle is [`benchmarks/double_ended_selection_sort_oracle.py`](../../double_ended_selection_sort_oracle.py). [`workload.json`](workload.json) covers empty and singleton inputs, source examples, repeated extrema, signed boundaries, malformed bounds, capacity edges, and maximum length.

## Pinned source

[TheAlgorithms/Python `unknown_sort.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/unknown_sort.py), pinned at commit `e1a2a8b016001309a73d5fec4818c35cca139795`. The source candidate remains `unknown_sort` in the catalog; its `merge_sort` function is mapped here by its actual algorithm.

Build and record with:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm double_ended_selection_sort --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm double_ended_selection_sort
```

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/d/double_ended_selection_sort.c`](../../../c/d/double_ended_selection_sort.c) |
| C3 | [`c3/d/double_ended_selection_sort.c3`](../../../c3/d/double_ended_selection_sort.c3) |
| C++ | [`cpp/d/double_ended_selection_sort.cpp`](../../../cpp/d/double_ended_selection_sort.cpp) |
| Elisa | [`elisa/d/double_ended_selection_sort.elisa`](../../../elisa/d/double_ended_selection_sort.elisa) |
| Nim | [`nim/d/double_ended_selection_sort.nim`](../../../nim/d/double_ended_selection_sort.nim) |
| Odin | [`odin/d/double_ended_selection_sort.odin`](../../../odin/d/double_ended_selection_sort.odin) |
| Rust | [`rust/d/double_ended_selection_sort.rs`](../../../rust/d/double_ended_selection_sort.rs) |
| V | [`v/d/double_ended_selection_sort.v`](../../../v/d/double_ended_selection_sort.v) |
| Zig | [`zig/d/double_ended_selection_sort.zig`](../../../zig/d/double_ended_selection_sort.zig) |
