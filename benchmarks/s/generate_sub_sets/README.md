# Generate Subsets

This benchmark ports the pinned JavaScript `generateSubSets` function. It enumerates all subsets in increasing bitmask order; within each subset it emits input elements in their original position order. Duplicate values remain separate input positions and can therefore produce identical value lists.

## Contract

- Input is `[n, values...]`, where `n` is 0 through 12 and must equal the number of following values.
- Each value is a signed safe JavaScript integer in `[-9007199254740991, 9007199254740991]`.
- For each mask from 0 through `2^n - 1`, the subset includes values whose corresponding bit is set, scanning input positions from lowest to highest. The empty subset is first.
- Output is binary: a little-endian u32 subset count, then for every subset a little-endian u32 element count followed by that subset's signed i64 values in little-endian order. The function returns the byte length, `-1` for malformed input, and `-2` when output capacity is too small.
- The workspace is 212,996 bytes, sufficient for the maximum 12-element output.

The pinned source permits lengths up to 32 but uses JavaScript's signed 32-bit bitwise shifts to compute the loop bound. The benchmark uses `n<=12`, where the source enumerates exactly `2^n` masks and the full output is practical to serialize. Its mask and element order, including the empty subset, are preserved.

[`workload.json`](workload.json) includes empty and singleton arrays, duplicates, negative and large safe integers, maximum length, malformed inputs, and insufficient output capacity. The independent oracle is [`benchmarks/generate_sub_sets_oracle.py`](../../generate_sub_sets_oracle.py).

## Pinned source

- JavaScript [`GenerateSubSets.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Bit-Manipulation/GenerateSubSets.js) loops through integer masks in ascending order and collects elements for set bits from left to right.

## Build and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm generate_sub_sets --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm generate_sub_sets
```

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/s/generate_sub_sets.c`](../../../c/s/generate_sub_sets.c) |
| C3 | [`c3/s/generate_sub_sets.c3`](../../../c3/s/generate_sub_sets.c3) |
| C++ | [`cpp/s/generate_sub_sets.cpp`](../../../cpp/s/generate_sub_sets.cpp) |
| Elisa | [`elisa/s/generate_sub_sets.elisa`](../../../elisa/s/generate_sub_sets.elisa) |
| Nim | [`nim/s/generate_sub_sets.nim`](../../../nim/s/generate_sub_sets.nim) |
| Odin | [`odin/s/generate_sub_sets.odin`](../../../odin/s/generate_sub_sets.odin) |
| Rust | [`rust/s/generate_sub_sets.rs`](../../../rust/s/generate_sub_sets.rs) |
| V | [`v/s/generate_sub_sets.v`](../../../v/s/generate_sub_sets.v) |
| Zig | [`zig/s/generate_sub_sets.zig`](../../../zig/s/generate_sub_sets.zig) |
