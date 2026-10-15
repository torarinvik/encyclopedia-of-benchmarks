# Palindrome Partitioning: All Partitions

This package ports the pinned JavaScript recursive search that returns every palindrome partition of a string.

## Contract

Input is a signed 64-bit array `[text_length, ASCII_byte...]`, with text length from 0 through 12 and byte values from 0 through 127. The length prefix allows the empty string. Invalid shape, length, or byte returns `-1`.

Output is a little-endian signed 64-bit vector. It starts with the partition count. Each partition is encoded as `[piece_count, end_position_1, ..., end_position_piece_count]`, where each end position is a one-based exclusive offset in the original text. These offsets uniquely identify every substring and keep the variable-size result compact. Partitions appear in the source's depth-first order: candidate prefixes are considered from shortest to longest. The empty string has one partition with zero pieces. Success returns the number of bytes written; insufficient capacity returns `-2` without writing.

The bound of 12 characters keeps the source's exhaustive output and recursion bounded. The contract uses ASCII bytes, which avoids the JavaScript source's UTF-16 string indexing differences for non-ASCII text.

## Pinned source

- JavaScript [`Recursive/PalindromePartitioning.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Recursive/PalindromePartitioning.js)

## Build and run

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm palindrome_partitioning_all_partitions --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/p/palindrome_partitioning_all_partitions/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/p/palindrome_partitioning_all_partitions.c`](../../../c/p/palindrome_partitioning_all_partitions.c) |
| C3 | [`c3/p/palindrome_partitioning_all_partitions.c3`](../../../c3/p/palindrome_partitioning_all_partitions.c3) |
| C++ | [`cpp/p/palindrome_partitioning_all_partitions.cpp`](../../../cpp/p/palindrome_partitioning_all_partitions.cpp) |
| Elisa | [`elisa/p/palindrome_partitioning_all_partitions.elisa`](../../../elisa/p/palindrome_partitioning_all_partitions.elisa) |
| Nim | [`nim/p/palindrome_partitioning_all_partitions.nim`](../../../nim/p/palindrome_partitioning_all_partitions.nim) |
| Odin | [`odin/p/palindrome_partitioning_all_partitions.odin`](../../../odin/p/palindrome_partitioning_all_partitions.odin) |
| Rust | [`rust/p/palindrome_partitioning_all_partitions.rs`](../../../rust/p/palindrome_partitioning_all_partitions.rs) |
| V | [`v/p/palindrome_partitioning_all_partitions.v`](../../../v/p/palindrome_partitioning_all_partitions.v) |
| Zig | [`zig/p/palindrome_partitioning_all_partitions.zig`](../../../zig/p/palindrome_partitioning_all_partitions.zig) |
