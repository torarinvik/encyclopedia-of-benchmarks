# Soundex encoder

This package adapts the pinned C# `SoundexEncoder.Encode` method to bounded ASCII input and a four-byte output buffer.

## Contract

- ABI: `i64_array_bytes_output`. The packed array is `[text_length, ASCII codes...]`; the ABI `input_length` is the packed array length and must equal `text_length + 1`. `text_length` must be 1..64 and every character code must be an uppercase or lowercase English letter (`A`-`Z` or `a`-`z`).
- The output is exactly four ASCII bytes: the uppercase first letter followed by three Soundex digits. Valid input codes are lowercased invariantly before processing.
- The source removes `h` and `w`, maps vowels `a/e/i/o/u/y` to 0 and consonant groups `bfpv=1`, `cgjkqsxz=2`, `dt=3`, `l=4`, `mn=5`, and `r=6`, collapses adjacent mapped codes, removes zero codes, removes the first remaining code if it matches the first letter's mapped code, keeps the first three digits, and pads with zeroes.
- The benchmark treats inputs that would fail in the source's lazy `CollapseLeadingDigit` iterator as invalid. A valid input must leave at least one nonzero code after vowel removal, and if the first code matches the first letter's group, at least one further code must remain for the iterator's unconditional `Current` read. This makes the benchmark's adapter behavior explicit for source exception edges.
- A null input pointer or any other invalid input returns `-1` before output storage is checked. A null output pointer or capacity below four returns `-2` without writes. Successful calls return 4.

`CollapseDoubles` runs before `OmitVowels`, so equal consonant codes separated by a vowel remain duplicated after the zero is removed. `h` and `w` are removed before mapping, so they do not separate equal codes.

## Workload and source

[`workload.json`](workload.json) covers canonical examples, mixed case, adjacent and vowel-separated duplicates, `h`/`w` removal, leading-code removal, padding, truncation, maximum length, source exception edges, malformed text, and output-capacity errors. The independent [oracle](../../soundex_encoder_oracle.py) models the pinned transformation order and iterator-safe input slice.

Pinned source: [TheAlgorithms/C-Sharp `SoundexEncoder.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Encoders/SoundexEncoder.cs), class `SoundexEncoder`, method `Encode`.

## Implementations

| Language | Port |
|---|---|
| C | [`c/s/soundex_encoder.c`](../../../c/s/soundex_encoder.c) |
| C3 | [`c3/s/soundex_encoder.c3`](../../../c3/s/soundex_encoder.c3) |
| C++ | [`cpp/s/soundex_encoder.cpp`](../../../cpp/s/soundex_encoder.cpp) |
| Elisa | [`elisa/s/soundex_encoder.elisa`](../../../elisa/s/soundex_encoder.elisa) |
| Nim | [`nim/s/soundex_encoder.nim`](../../../nim/s/soundex_encoder.nim) |
| Odin | [`odin/s/soundex_encoder.odin`](../../../odin/s/soundex_encoder.odin) |
| Rust | [`rust/s/soundex_encoder.rs`](../../../rust/s/soundex_encoder.rs) |
| V | [`v/s/soundex_encoder.v`](../../../v/s/soundex_encoder.v) |
| Zig | [`zig/s/soundex_encoder.zig`](../../../zig/s/soundex_encoder.zig) |
