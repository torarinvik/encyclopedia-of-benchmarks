# Shortest palindrome

Form the shortest palindrome by adding characters to the left of the input. The pinned Rust implementation builds a KMP prefix table, matches the original against its reversal, and prepends the unmatched suffix in reverse order.

## Contract

- Input is a sequence of 0 through 64 printable ASCII byte values (`32..126`). Each byte represents one source character.
- Return the shortest palindrome formed by prepending bytes; empty input returns an empty output.
- Null nonempty, overlength, or nonprintable input returns `-1`. Insufficient output capacity returns `-2`. Error results leave the output buffer untouched.
- The output needs at most 127 bytes, so the workspace is 127 bytes.

The Rust source operates on Unicode scalar values. This benchmark uses printable ASCII so every input byte corresponds to exactly one source character.

## Workload and oracle

[`workload.json`](workload.json) covers empty input, already-palindromic and extended strings, repeated prefixes, the maximum output length, malformed bytes, and output capacity boundaries. The independent oracle checks candidate prefixes directly rather than using KMP: [`shortest_palindrome_oracle.py`](../../shortest_palindrome_oracle.py).

## Reviewed source

[TheAlgorithms/Rust `shortest_palindrome.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/string/shortest_palindrome.rs)

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm shortest_palindrome --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm shortest_palindrome
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm shortest_palindrome
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/shortest_palindrome.c`](../../../c/s/shortest_palindrome.c) |
| C3 | [`c3/s/shortest_palindrome.c3`](../../../c3/s/shortest_palindrome.c3) |
| C++ | [`cpp/s/shortest_palindrome.cpp`](../../../cpp/s/shortest_palindrome.cpp) |
| Elisa | [`elisa/s/shortest_palindrome.elisa`](../../../elisa/s/shortest_palindrome.elisa) |
| Nim | [`nim/s/shortest_palindrome.nim`](../../../nim/s/shortest_palindrome.nim) |
| Odin | [`odin/s/shortest_palindrome.odin`](../../../odin/s/shortest_palindrome.odin) |
| Rust | [`rust/s/shortest_palindrome.rs`](../../../rust/s/shortest_palindrome.rs) |
| V | [`v/s/shortest_palindrome.v`](../../../v/s/shortest_palindrome.v) |
| Zig | [`zig/s/shortest_palindrome.zig`](../../../zig/s/shortest_palindrome.zig) |
