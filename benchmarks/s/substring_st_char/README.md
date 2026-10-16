# Substring from character

This benchmark ports the pinned AArch64 `subStringStChar` helper. It finds the first occurrence of a byte and copies from that point for up to the requested count, stopping at the source string terminator.

## Contract

- Input is `[target_byte, requested_count, byte_0, ...]`, with 0 to 128 ASCII byte codes in `1..=127`. The target is in `1..=127`, the count is in `[0,64]`, and the end of the explicit list represents the C-string NUL terminator.
- If the target is absent, the source returns `-1`. Otherwise the ABI returns `copied_length * 300000 + sum((position + 1) * byte)` for the copied suffix. Invalid shape or fields also return `-1`.
- The source copies the matching byte before checking whether the requested count was reached. Thus a zero count still copies one byte when the target exists.
- The source is byte-oriented. UTF-8 and non-ASCII byte codes are outside the domain.

## Source

Pinned source: [TheAlgorithms/AArch64_Assembly `substring.s`](https://github.com/TheAlgorithms/AArch64_Assembly/blob/cb138a856a3af14d3d3dfcd2743d43841eec566f/string/substring.s), commit `cb138a856a3af14d3d3dfcd2743d43841eec566f`, helper `subStringStChar`. Its header attributes the original code to Rosetta Code under CC BY-SA 4.0. The source example finds `c` in the alphabet and copies five bytes, producing `cdefg`.

## Workload and running

[`workload.json`](workload.json) covers the pinned example, repeated targets, zero-count behavior, early terminators, absent targets, empty text, maximum text, and invalid fields. Oracle: [`benchmarks/substring_st_char_oracle.py`](../../substring_st_char_oracle.py).

Build and verify a selected port with:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm substring_st_char --language rust
python3 benchmarks/verify_i64_array_scalar.py --algorithm substring_st_char --languages rust
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/substring_st_char.c`](../../../c/s/substring_st_char.c) |
| C3 | [`c3/s/substring_st_char.c3`](../../../c3/s/substring_st_char.c3) |
| C++ | [`cpp/s/substring_st_char.cpp`](../../../cpp/s/substring_st_char.cpp) |
| Elisa | [`elisa/s/substring_st_char.elisa`](../../../elisa/s/substring_st_char.elisa) |
| Nim | [`nim/s/substring_st_char.nim`](../../../nim/s/substring_st_char.nim) |
| Odin | [`odin/s/substring_st_char.odin`](../../../odin/s/substring_st_char.odin) |
| Rust | [`rust/s/substring_st_char.rs`](../../../rust/s/substring_st_char.rs) |
| V | [`v/s/substring_st_char.v`](../../../v/s/substring_st_char.v) |
| Zig | [`zig/s/substring_st_char.zig`](../../../zig/s/substring_st_char.zig) |
