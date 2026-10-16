# Lipogram

A lipogram omits one or more letters from the alphabet. Given a text and an expected set of missing lowercase letters, return whether the text omits exactly that set.

## Contract

The `i64_array_scalar` input is `[byte_length, ASCII_text_bytes..., missing_mask]`. `byte_length` is 0..1024, and the packed length must be exactly `byte_length + 2`. Text bytes may be ASCII letters (`A`–`Z`, `a`–`z`) or ASCII whitespace (tab, line feed, vertical tab, form feed, carriage return, and space). `missing_mask` is an integer in 0..67,108,863; bit `i` represents lowercase letter `'a' + i`, for `i` 0..25. Repeated bits are naturally represented once, matching the source's set semantics.

The result is `1` if the letters absent from the text equal the mask, otherwise `0`. Invalid packing, text bytes, or mask returns `-1`, mapping the source's error result to the scalar ABI. The ASCII domain preserves the source's lowercase and ASCII-letter behavior while making its Unicode whitespace/lowercase rules portable.

## Source and related algorithms

The pinned Rust source is [`src/string/lipogram.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/string/lipogram.rs) at commit `fed66cb0c74c4a939ec5163648458a8c2b46fd4c`. It validates that every expected missing character is lowercase, rejects text characters that are neither ASCII alphabetic nor whitespace, lowercases the text, computes the missing ASCII letters `a` through `z`, and compares that set with the caller-provided set. The benchmark packs that expected set as a 26-bit mask. The source repository is licensed under [MIT](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/LICENSE). [`is_pangram`](../../i/is_pangram/README.md) only asks whether no letters are missing; this benchmark also checks a specified nonempty missing-letter set.

[`workload.json`](workload.json) covers empty text, a pangram, single and multiple missing letters, a valid mismatch, whitespace, and invalid packed values. The independent oracle is [`lipogram_oracle.py`](../../lipogram_oracle.py); it compares Python sets of used and expected letters. The nine ports use the shared `i64_array_scalar` ABI.

## Build, record, and verify

Build and record a Rust sample with:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm lipogram --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/l/lipogram/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms lipogram
```

| Language | Source |
| --- | --- |
| C | [`c/l/lipogram.c`](../../../c/l/lipogram.c) |
| C3 | [`c3/l/lipogram.c3`](../../../c3/l/lipogram.c3) |
| C++ | [`cpp/l/lipogram.cpp`](../../../cpp/l/lipogram.cpp) |
| Elisa | [`elisa/l/lipogram.elisa`](../../../elisa/l/lipogram.elisa) |
| Nim | [`nim/l/lipogram.nim`](../../../nim/l/lipogram.nim) |
| Odin | [`odin/l/lipogram.odin`](../../../odin/l/lipogram.odin) |
| Rust | [`rust/l/lipogram.rs`](../../../rust/l/lipogram.rs) |
| V | [`v/l/lipogram.v`](../../../v/l/lipogram.v) |
| Zig | [`zig/l/lipogram.zig`](../../../zig/l/lipogram.zig) |
