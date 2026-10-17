# Scramble strings

This package adapts the pinned JavaScript `isScramble` routine. It reports whether the second string can be formed by recursively partitioning the first string and optionally swapping the two parts at each partition.

## Contract

- ABI: `i64_array_scalar`. Packed input is `[n, first_ascii..., second_ascii...]`; each string has length `n`, and the total array length must be exactly `2*n + 1`.
- `n` is in `[0, 8]`. Both strings contain only lowercase ASCII letters (`a`-`z`). The empty strings are equal and return 1.
- Return 1 when the strings are scrambles and 0 otherwise. Invalid framing or characters return `-1`.
- The recursive helper checks memoized states, short-circuits identical substrings, rejects unequal character counts, and tests straight partitions before swapped partitions for split points from left to right.

The bounded lowercase alphabet avoids JavaScript UTF-16 indexing and object-key edge cases. The equal-length input contract also makes the source's concatenated memo key unambiguous. The local ports memoize equivalent `(first substring, second substring)` states while preserving the source's recursion and branch order.

## Workload and source

[`workload.json`](workload.json) covers empty strings, identity, positive and negative examples, repeated letters, straight and swapped splits, the maximum length, malformed counts, and non-lowercase inputs. The independent [oracle](../../scramble_strings_oracle.py) follows the source's multiset check and recursive split order.

Pinned source: [TheAlgorithms/JavaScript `ScrambleStrings.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/String/ScrambleStrings.js), function `isScramble` and helper `helper`.

## Implementations

| Language | Port |
|---|---|
| C | [`c/s/scramble_strings.c`](../../../c/s/scramble_strings.c) |
| C3 | [`c3/s/scramble_strings.c3`](../../../c3/s/scramble_strings.c3) |
| C++ | [`cpp/s/scramble_strings.cpp`](../../../cpp/s/scramble_strings.cpp) |
| Elisa | [`elisa/s/scramble_strings.elisa`](../../../elisa/s/scramble_strings.elisa) |
| Nim | [`nim/s/scramble_strings.nim`](../../../nim/s/scramble_strings.nim) |
| Odin | [`odin/s/scramble_strings.odin`](../../../odin/s/scramble_strings.odin) |
| Rust | [`rust/s/scramble_strings.rs`](../../../rust/s/scramble_strings.rs) |
| V | [`v/s/scramble_strings.v`](../../../v/s/scramble_strings.v) |
| Zig | [`zig/s/scramble_strings.zig`](../../../zig/s/scramble_strings.zig) |
