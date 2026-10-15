# Z algorithm

Compute the Z-array of an input sequence. At index `i`, the result is the length of the longest prefix of the sequence that also matches the subsequence beginning at `i`. The source convention sets `z[0]` to zero.

## Contract

- Input is `[length, item_0, ..., item_(length-1)]`, where `length` is from 0 through 2,047. Items are arbitrary signed 64-bit values and equality is exact.
- Output contains one unsigned 32-bit little-endian Z value per input item. The function returns the number of values written. Empty input returns an empty array and `0`; malformed input returns `-1`; insufficient output capacity returns `-2`.
- The result has exactly `length` entries. For nonempty input, the first entry is zero, matching the pinned Rust `z_array` function rather than conventions that assign the first entry the sequence length.

## Relationship to Z algorithm search

This benchmark ports the source's raw `z_array` operation. The same Rust module also has `match_pattern`, which filters Z values into zero-based match offsets. [`z_algorithm_search`](../z_algorithm_search/README.md) is a separate all-occurrences search contract based on the R source; it uses case-insensitive ASCII and returns one-based positions. A raw prefix-match length at every input index is a different output from a list of pattern-match positions.

## Pinned source

- [Rust `z_algorithm.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74a4c939ec5163648458a8c2b46fd4c/src/string/z_algorithm.rs)

The source's generic `z_array` invokes its Z engine from index one, leaving the first array element zero. Its helper for `match_pattern` starts at index zero and selects positions where the Z value equals the pattern length.

## Workload and build

[`workload.json`](workload.json) covers empty and singleton inputs, the pinned source examples, repeated prefixes, signed-symbol equality, and malformed packed arrays. The shared byte-output runner uses a separate direct-prefix comparison oracle.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm z_algorithm --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/z/z_algorithm/rust/build.json
```

The nine ports are in `c/z/z_algorithm.c`, `c3/z/z_algorithm.c3`, `cpp/z/z_algorithm.cpp`, `elisa/z/z_algorithm.elisa`, `nim/z/z_algorithm.nim`, `odin/z/z_algorithm.odin`, `rust/z/z_algorithm.rs`, `v/z/z_algorithm.v`, and `zig/z/z_algorithm.zig`.
