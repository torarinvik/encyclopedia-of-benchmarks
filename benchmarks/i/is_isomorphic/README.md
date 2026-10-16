# Isomorphic strings

Determine whether one bounded ASCII string can be mapped to another with a consistent one-to-one character substitution.

## Contract

- ABI: `i64_array_scalar`. Input is `[source_length, target_length, source_codepoints..., target_codepoints...]`.
- Each length is 0 through 8. Each string codepoint is in `0..=127`; NUL is ordinary string data. The packed array must contain exactly both declared strings.
- The longest valid packed array has 18 elements. The workload admits up to 20 elements so the over-bound 9+9-codepoint case reaches the implementation and returns `-1`.
- Unequal string lengths return `0`. For equal lengths, return `1` when every source codepoint maps consistently to one target codepoint and no two source codepoints map to the same target; otherwise return `0`.
- Malformed packed arrays, lengths outside the bound, or codepoints outside ASCII return `-1`.

## Source and workload

This follows [TheAlgorithms/Python `is_isomorphic.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/is_isomorphic.py). The source compares Python strings and therefore supports arbitrary Unicode; this benchmark narrows codepoints to ASCII for a fixed cross-language ABI. The workload includes the source examples, empty strings, repeated and NUL codepoints, unequal lengths, boundary values, and malformed packed input.

Build and record Rust with:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm is_isomorphic --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/i/is_isomorphic/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms is_isomorphic --languages rust
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/i/is_isomorphic.c`](../../../c/i/is_isomorphic.c) |
| C3 | [`c3/i/is_isomorphic.c3`](../../../c3/i/is_isomorphic.c3) |
| C++ | [`cpp/i/is_isomorphic.cpp`](../../../cpp/i/is_isomorphic.cpp) |
| Elisa | [`elisa/i/is_isomorphic.elisa`](../../../elisa/i/is_isomorphic.elisa) |
| Nim | [`nim/i/is_isomorphic.nim`](../../../nim/i/is_isomorphic.nim) |
| Odin | [`odin/i/is_isomorphic.odin`](../../../odin/i/is_isomorphic.odin) |
| Rust | [`rust/i/is_isomorphic.rs`](../../../rust/i/is_isomorphic.rs) |
| V | [`v/i/is_isomorphic.v`](../../../v/i/is_isomorphic.v) |
| Zig | [`zig/i/is_isomorphic.zig`](../../../zig/i/is_isomorphic.zig) |
