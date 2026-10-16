# Substring to end

This benchmark ports the pinned AArch64 `subStringEnd` helper, which copies bytes from a zero-based starting offset through the C-string terminator.

## Contract

- Input is `[start_index, byte_0, ...]`, with zero to 128 ASCII byte codes in `1..=127`. `start_index` must be between zero and the text length, inclusive. The end of the explicit list represents the source NUL terminator.
- The bounded ABI returns `copied_length * 1100000 + sum((position + 1) * byte)` for the suffix. The base exceeds the maximum possible positional checksum, keeping different output lengths distinct. Invalid shape or fields return `-1`.
- The source is byte-oriented. UTF-8 and non-ASCII byte codes are outside the benchmark domain.

## Source

Pinned source: [TheAlgorithms/AArch64_Assembly `substring.s`](https://github.com/TheAlgorithms/AArch64_Assembly/blob/cb138a856a3af14d3d3dfcd2743d43841eec566f/string/substring.s), commit `cb138a856a3af14d3d3dfcd2743d43841eec566f`, helper `subStringEnd`. Its header attributes the original code to Rosetta Code under CC BY-SA 4.0.

## Workload and running

[`workload.json`](workload.json) covers the pinned suffix example, start and end offsets, empty suffix, maximum text, the distinct 70-byte and 71-byte checksum boundary cases, and invalid fields. Oracle: [`benchmarks/substring_end_oracle.py`](../../substring_end_oracle.py).

Build and verify a selected port with:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm substring_end --language rust
python3 benchmarks/verify_i64_array_scalar.py --algorithm substring_end --languages rust
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/substring_end.c`](../../../c/s/substring_end.c) |
| C3 | [`c3/s/substring_end.c3`](../../../c3/s/substring_end.c3) |
| C++ | [`cpp/s/substring_end.cpp`](../../../cpp/s/substring_end.cpp) |
| Elisa | [`elisa/s/substring_end.elisa`](../../../elisa/s/substring_end.elisa) |
| Nim | [`nim/s/substring_end.nim`](../../../nim/s/substring_end.nim) |
| Odin | [`odin/s/substring_end.odin`](../../../odin/s/substring_end.odin) |
| Rust | [`rust/s/substring_end.rs`](../../../rust/s/substring_end.rs) |
| V | [`v/s/substring_end.v`](../../../v/s/substring_end.v) |
| Zig | [`zig/s/substring_end.zig`](../../../zig/s/substring_end.zig) |
