# join

This package ports the pinned Python `join(separator, separated)` function, which concatenates a list of strings with a separator and does not add a separator after the last item.

## Contract

- Input is `[separator_length, item_count, separator_bytes..., item_length, item_bytes..., ...]`. Separator and items are ASCII byte strings. The separator is at most 32 bytes; there are at most 32 items, each at most 64 bytes. Empty separators, empty item lists, and empty items are valid.
- The ASCII-only bounds exclude the source's general Unicode string domain. This byte-array ABI also cannot represent Python objects of non-string type; the source raises `Exception("join() accepts only strings")` for those values.
- Output is the exact concatenation as ASCII bytes. Malformed layout or bytes outside `0..127` return `-1`; insufficient capacity or a null output pointer returns `-2`. Maximum input length is 2,114 i64 values and maximum output is 3,040 bytes.

The independent oracle is [`benchmarks/join_oracle.py`](../../join_oracle.py). The workload covers the source examples, empty separators/lists/items, control bytes, malformed shapes and bounds, capacity edges, and the maximum input.

Pinned source: [TheAlgorithms/Python `strings/join.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/join.py), commit `e1a2a8b016001309a73d5fec4818c35cca139795`.

Build and record with:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm join --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm join
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/j/join.c`](../../../c/j/join.c) |
| C3 | [`c3/j/join.c3`](../../../c3/j/join.c3) |
| C++ | [`cpp/j/join.cpp`](../../../cpp/j/join.cpp) |
| Elisa | [`elisa/j/join.elisa`](../../../elisa/j/join.elisa) |
| Nim | [`nim/j/join.nim`](../../../nim/j/join.nim) |
| Odin | [`odin/j/join.odin`](../../../odin/j/join.odin) |
| Rust | [`rust/j/join.rs`](../../../rust/j/join.rs) |
| V | [`v/j/join.v`](../../../v/j/join.v) |
| Zig | [`zig/j/join.zig`](../../../zig/j/join.zig) |
