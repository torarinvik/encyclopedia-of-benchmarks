# unknown_sort

This package ports the pinned Python `merge_sort(collection)` function from `sorts/unknown_sort.py`. Despite its name and docstring, the implementation repeatedly extracts extrema; it is a double-ended selection sort with quadratic worst-case work.

## Contract

- Input is an array of at most 256 signed i64 values. Empty and singleton arrays are valid. The source accepts general comparable Python objects; this benchmark restricts it to signed i64 integers.
- On each pass, the source selects the first minimum and first maximum, appends them to separate buffers, removes the first matching minimum, then removes the first matching maximum from the remaining collection. It reverses the max buffer and returns `minima + optional middle + reversed maxima`. The wrappers copy the input into local mutable storage and preserve this extraction and tie-removal behavior.
- Output is the resulting signed i64 sequence encoded in little-endian order, without a length header. Malformed input returns `-1`; insufficient capacity or a null output pointer returns `-2`. Maximum input is 256 values and maximum output is 2,048 bytes.

The independent oracle is [`benchmarks/unknown_sort_oracle.py`](../../unknown_sort_oracle.py). The workload covers empty/singleton inputs, source examples, duplicate extrema and tie behavior, signed i64 boundaries, malformed bounds, capacity edges, and maximum length.

Pinned source: [TheAlgorithms/Python `unknown_sort.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/unknown_sort.py), commit `e1a2a8b016001309a73d5fec4818c35cca139795`.

Build and record with:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm unknown_sort --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm unknown_sort
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/u/unknown_sort.c`](../../../c/u/unknown_sort.c) |
| C3 | [`c3/u/unknown_sort.c3`](../../../c3/u/unknown_sort.c3) |
| C++ | [`cpp/u/unknown_sort.cpp`](../../../cpp/u/unknown_sort.cpp) |
| Elisa | [`elisa/u/unknown_sort.elisa`](../../../elisa/u/unknown_sort.elisa) |
| Nim | [`nim/u/unknown_sort.nim`](../../../nim/u/unknown_sort.nim) |
| Odin | [`odin/u/unknown_sort.odin`](../../../odin/u/unknown_sort.odin) |
| Rust | [`rust/u/unknown_sort.rs`](../../../rust/u/unknown_sort.rs) |
| V | [`v/u/unknown_sort.v`](../../../v/u/unknown_sort.v) |
| Zig | [`zig/u/unknown_sort.zig`](../../../zig/u/unknown_sort.zig) |
