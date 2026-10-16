# Substring minus last byte

This benchmark ports the pinned AArch64 `subStringMinus` helper, which copies a C string and removes its final byte.

## Contract

- Input is a nonempty sequence of 1 to 128 ASCII byte codes in `1..=127`. The source routine decrements its output length before storing a terminator; empty input underflows that length and writes before the buffer, so empty input is excluded.
- The bounded ABI returns `copied_length * 1100000 + sum((position + 1) * byte)` for all but the last byte. The base exceeds the maximum possible positional checksum, keeping different output lengths distinct. Invalid shape or fields return `-1`.
- The source is byte-oriented. UTF-8 and non-ASCII byte codes are outside the benchmark domain.

## Source

Pinned source: [TheAlgorithms/AArch64_Assembly `substring.s`](https://github.com/TheAlgorithms/AArch64_Assembly/blob/cb138a856a3af14d3d3dfcd2743d43841eec566f/string/substring.s), commit `cb138a856a3af14d3d3dfcd2743d43841eec566f`, helper `subStringMinus`. Its header attributes the original code to Rosetta Code under CC BY-SA 4.0.

## Workload and running

[`workload.json`](workload.json) covers the pinned alphabet example, a one-byte string, repeated bytes, whitespace, maximum text, distinct 70-byte and 71-byte checksum boundary cases, and invalid empty/non-ASCII inputs. Oracle: [`benchmarks/substring_minus_oracle.py`](../../substring_minus_oracle.py).

Build and verify a selected port with:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm substring_minus --language rust
python3 benchmarks/verify_i64_array_scalar.py --algorithm substring_minus --languages rust
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/substring_minus.c`](../../../c/s/substring_minus.c) |
| C3 | [`c3/s/substring_minus.c3`](../../../c3/s/substring_minus.c3) |
| C++ | [`cpp/s/substring_minus.cpp`](../../../cpp/s/substring_minus.cpp) |
| Elisa | [`elisa/s/substring_minus.elisa`](../../../elisa/s/substring_minus.elisa) |
| Nim | [`nim/s/substring_minus.nim`](../../../nim/s/substring_minus.nim) |
| Odin | [`odin/s/substring_minus.odin`](../../../odin/s/substring_minus.odin) |
| Rust | [`rust/s/substring_minus.rs`](../../../rust/s/substring_minus.rs) |
| V | [`v/s/substring_minus.v`](../../../v/s/substring_minus.v) |
| Zig | [`zig/s/substring_minus.zig`](../../../zig/s/substring_minus.zig) |
