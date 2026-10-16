# Substring

This benchmark ports the pinned AArch64 `subStringNbChar` helper. Given a byte string, a zero-based starting offset, and a requested count, it copies up to that many bytes into the result, stopping early at the source string's terminator.

## Contract

- Input is `[start_index, requested_count, byte_0, ...]`, with 0 to 128 ASCII byte codes in `1..=127`. The leading fields are nonnegative; `start_index` is at most the string length and `requested_count` is in `[0,64]`.
- The source uses a C-style zero terminator. This contract excludes zero from the explicit byte list, so the end of the list acts as the terminator. UTF-8 and non-ASCII bytes are outside the domain.
- The source copies each byte before checking whether the requested count has been reached. Thus `requested_count == 0` copies one byte when the start is before the end, and copies none when starting at the end.
- The ABI returns `copied_length * 300000 + sum((position + 1) * byte)` for the copied bytes. The positional checksum is below 300000 throughout the bounded domain, so the result encodes the copied length and a deterministic positional checksum. Invalid shapes or fields return `-1`.
- This package benchmarks the fixed-range helper called by the pinned program; its separate suffix, minus-last, start-character, and start-substring helpers are not folded into this call.

## Source

Pinned source: [TheAlgorithms/AArch64_Assembly `substring.s`](https://github.com/TheAlgorithms/AArch64_Assembly/blob/cb138a856a3af14d3d3dfcd2743d43841eec566f/string/substring.s), commit `cb138a856a3af14d3d3dfcd2743d43841eec566f`. The source example uses `subStringNbChar` on `abcdefghijklmnopqrstuvwxyz` at offset 22 for 4 bytes, producing `wxyz`. Its file header attributes the original code to Rosetta Code under CC BY-SA 4.0.

## Workload and running

[`workload.json`](workload.json) covers the pinned example, truncation at the terminator, offsets at both ends, zero-count source behavior, empty text, maximum bounded text, and invalid fields. The independent oracle is [`benchmarks/substring_oracle.py`](../../substring_oracle.py).

Build and verify a selected port with:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm substring --language rust
python3 benchmarks/verify_i64_array_scalar.py --algorithm substring --languages rust
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/substring.c`](../../../c/s/substring.c) |
| C3 | [`c3/s/substring.c3`](../../../c3/s/substring.c3) |
| C++ | [`cpp/s/substring.cpp`](../../../cpp/s/substring.cpp) |
| Elisa | [`elisa/s/substring.elisa`](../../../elisa/s/substring.elisa) |
| Nim | [`nim/s/substring.nim`](../../../nim/s/substring.nim) |
| Odin | [`odin/s/substring.odin`](../../../odin/s/substring.odin) |
| Rust | [`rust/s/substring.rs`](../../../rust/s/substring.rs) |
| V | [`v/s/substring.v`](../../../v/s/substring.v) |
| Zig | [`zig/s/substring.zig`](../../../zig/s/substring.zig) |
