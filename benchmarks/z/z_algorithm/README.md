# Z algorithm

Compute the Z-array of an input sequence. At index `i`, the result is the length of the longest prefix of the sequence that also matches the subsequence beginning at `i`. The source convention sets `z[0]` to zero.

## Contract

- Input is `[length, item_0, ..., item_(length-1)]`, where `length` is from 0 through 4,095. Items are arbitrary signed 64-bit values and equality is exact.
- Output contains one unsigned 32-bit little-endian Z value per input item. The function returns the number of values written. Empty input returns an empty array and `0`; malformed input returns `-1`; insufficient output capacity returns `-2`.
- A null input returns `-1`. A null output returns `-2` for a nonempty result and is accepted for an empty result.
- The result has exactly `length` entries. For nonempty input, the first entry is zero, matching the pinned Rust `z_array` function rather than conventions that assign the first entry the sequence length.

The maintained Z-box lets the implementation compute the array in O(n) time
and O(n) working space for a sequence of n symbols.

## Relationship to Z algorithm search

The former `z_algorithm_search` benchmark applied ASCII case folding, computed
the same Z-array on pattern, separator, and text, and filtered it into one-based
match positions. It has been consolidated here. The raw-array interface does not
perform case folding or return match positions: callers can prepare the sequence
and filter the returned values, and must handle an empty pattern separately.
The expanded bound accommodates the former profile's largest prepared sequence.
The former `zblock_substring_search` package also used this Z computation and
filtered it to an overlapping-match count. It is consolidated here; callers must
count matching Z values themselves, as this interface returns the full array.

## Pinned source

- [Rust `z_algorithm.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74a4c939ec5163648458a8c2b46fd4c/src/string/z_algorithm.rs)
- [C++ `z_function.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/strings/z_function.cpp)
- [Additional C++ `z_function.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/strings/z_function.cpp)
- [Python `z_function.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/z_function.py)
- [R `z.algorithm.search.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/searches/z.algorithm.search.r)
- [C# `ZblockSubstringSearch.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Strings/PatternMatching/ZblockSubstringSearch.cs)

The source's generic `z_array` invokes its Z engine from index one, leaving the first array element zero. Its helper for `match_pattern` starts at index zero and selects positions where the Z value equals the pattern length.
The C++ and Python Z-function sources compute this same raw array. Their former
ASCII-only `z_function` package was consolidated here; this contract supports
arbitrary signed symbols and up to 4,095 elements. The expanded bound is
written but unverified.

## Workload and build

[`workload.json`](workload.json) covers empty and singleton inputs, the pinned source examples, repeated prefixes, signed-symbol equality, and malformed packed arrays. The shared byte-output runner uses a separate direct-prefix comparison oracle.
The verifier includes an independent prefix-comparison reference, null and
short-output cases, a maximum-length sequence, and a repeated-prefix sequence.
Its 16,380-byte workspace supplies the checker's explicit-capacity framing.
These checks are unexecuted.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm z_algorithm --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/z/z_algorithm/rust/build.json
```

The ten source drafts are in `c/z/z_algorithm.c`, `c3/z/z_algorithm.c3`,
`cpp/z/z_algorithm.cpp`, `elisa/z/z_algorithm.elisa`,
[`mojo/z/z_algorithm.mojo`](../../../mojo/z/z_algorithm.mojo),
`nim/z/z_algorithm.nim`, `odin/z/z_algorithm.odin`, `rust/z/z_algorithm.rs`,
`v/z/z_algorithm.v`, and `zig/z/z_algorithm.zig`. The Elisa draft uses views
after validating its ABI references. The drafts and consolidation have not
been compiled or run.
