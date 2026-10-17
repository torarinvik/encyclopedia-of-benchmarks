# Suffix array

Return every starting index in lexicographic order of the suffix beginning at that index. The package covers the canonical Java suffix-array implementation and the matching Rust Manber–Myers alias over bounded ASCII input.

## Contract

The i64_array_bytes_output input is [text_length, ascii_codes...]. Text length is 0..64, and every code is ASCII 0..127, including NUL. The signed 64-bit input contains exactly 1 + text_length values.

For a nonempty text, output all zero-based suffix starts sorted by the suffix contents in lexicographic order. The output is a sequence of signed little-endian 64-bit integers; the return value is the number of bytes written. Empty text produces no suffix starts and returns 0. Invalid input returns -1. A null output pointer returns -2 even for empty text. A nonnull zero-capacity output succeeds for empty text. An undersized buffer returns -2 without writing.

The ASCII restriction keeps byte offsets aligned with Java character positions and Rust UTF-8 byte offsets. The bounds cap output at 512 bytes. The pinned Java implementation uses rank doubling. The matching Rust source first sorts full suffix slices, so this contract makes no O(n log n) complexity claim.

## Workload and oracle

[workload.json](workload.json) covers the source's banana suffix ordering, empty and singleton inputs, repeated and periodic characters, NUL and upper ASCII values, maximum text length, malformed framing, and output-pointer/capacity behavior. The independent [oracle](../../suffix_array_oracle.py) sorts bounded suffix slices and encodes their start positions.

## Pinned sources

- [TheAlgorithms/Java SuffixArray.java at e43ec3897e48f23843972d02cd05a5bb1b6864a2](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/SuffixArray.java)
- [TheAlgorithms/Rust suffix_array_manber_myers.rs at fed66cb0c74c4a939ec5163648458a8c2b46fd4c](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/string/suffix_array_manber_myers.rs)

The catalog alias suffix_array_manber_myers uses this same package contract. The separate Rust suffix_array.rs source is excluded from this source claim pending its own comparator and UTF-8 review.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/s/suffix_array.c](../../../c/s/suffix_array.c) |
| C3 | [c3/s/suffix_array.c3](../../../c3/s/suffix_array.c3) |
| C++ | [cpp/s/suffix_array.cpp](../../../cpp/s/suffix_array.cpp) |
| Elisa | [elisa/s/suffix_array.elisa](../../../elisa/s/suffix_array.elisa) |
| Nim | [nim/s/suffix_array.nim](../../../nim/s/suffix_array.nim) |
| Odin | [odin/s/suffix_array.odin](../../../odin/s/suffix_array.odin) |
| Rust | [rust/s/suffix_array.rs](../../../rust/s/suffix_array.rs) |
| V | [v/s/suffix_array.v](../../../v/s/suffix_array.v) |
| Zig | [zig/s/suffix_array.zig](../../../zig/s/suffix_array.zig) |
