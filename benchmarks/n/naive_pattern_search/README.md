# Naive pattern search

Find the first exact occurrence of a pattern in a text by checking candidate windows from left to right. This follows the pinned [TheAlgorithms Julia implementation](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/strings/naive_pattern_search.jl).

## Contract

- The i64_array_scalar ABI accepts [text_length, pattern_length, text_bytes..., pattern_bytes...] and returns the zero-based start of the first match, or -1 when no match exists.
- Text and pattern are ASCII byte sequences with values 0 through 127. Each can contain at most 255 bytes. The pattern length must not exceed the text length; empty text is allowed only with an empty pattern.
- The pinned Julia source returns a formatted string containing the pattern and its zero-based index. This benchmark uses the index as the output so search work can be compared independently of string formatting. The pinned loop includes one extra candidate start (`text_length - pattern_length + 1`) and can index past the text on some no-match inputs; the ports use the conventional final valid start (`text_length - pattern_length`) to avoid that source defect.
- An empty pattern returns -1, matching the pinned function's "No matches found" result. A nonempty pattern longer than the text is excluded because the source can index beyond the text.
- Malformed lengths or byte values return -2. The scan uses O((n-m+1)m) worst-case time and O(1) auxiliary space.

[workload.json](workload.json) covers first and overlapping matches, no match, repeated data, empty patterns, zero bytes, invalid bytes, and malformed lengths.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/n/naive_pattern_search.c](../../../c/n/naive_pattern_search.c) |
| C3 | [c3/n/naive_pattern_search.c3](../../../c3/n/naive_pattern_search.c3) |
| C++ | [cpp/n/naive_pattern_search.cpp](../../../cpp/n/naive_pattern_search.cpp) |
| Elisa | [elisa/n/naive_pattern_search.elisa](../../../elisa/n/naive_pattern_search.elisa) |
| Nim | [nim/n/naive_pattern_search.nim](../../../nim/n/naive_pattern_search.nim) |
| Odin | [odin/n/naive_pattern_search.odin](../../../odin/n/naive_pattern_search.odin) |
| Rust | [rust/n/naive_pattern_search.rs](../../../rust/n/naive_pattern_search.rs) |
| V | [v/n/naive_pattern_search.v](../../../v/n/naive_pattern_search.v) |
| Zig | [zig/n/naive_pattern_search.zig](../../../zig/n/naive_pattern_search.zig) |

## Build and run

Build and run an implementation with the shared scalar-array ABI:

    python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm naive_pattern_search --language rust
    python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/n/naive_pattern_search/rust/build.json
