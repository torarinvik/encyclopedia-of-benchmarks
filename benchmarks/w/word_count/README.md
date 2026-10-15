# Word count

## Contract

This benchmark follows the pinned C `word_count` routine, which counts tokens separated by the literal ASCII space byte and counts exact, case-sensitive matches for one requested word. Input is packed as `[text_length, text_bytes..., query_length, query_bytes...]`. Text bytes may be non-NUL ASCII values `1..127`; the query may be empty and is limited to 49 bytes. Other byte values are invalid.

To stay within the C source's fixed buffers without triggering its boundary overflows, text length is at most 999 bytes, each resulting token is at most 49 bytes, and there are at most 20 tokens. Leading, trailing, and repeated spaces create empty tokens, matching the source's split loop. The C routine returns the total token count and writes the requested word's frequency to its output structure. The benchmark encodes both values as two little-endian signed 64-bit integers `[total_words, matches]`; a successful call returns the fixed output byte count `16`. Invalid packing or an overlong token returns `-1`; more than 20 tokens returns `-2`. A too-small output buffer also returns `-2`.

The catalog also includes a Julia `word_count` filename match, but that source lowercases input and counts regex-extracted words into a dictionary. It does not implement the C routine's requested-word query or literal-space tokenization, so this benchmark contract follows the C API and does not claim that the Julia source is semantically equivalent.

## Workload and implementation

[`workload.json`](workload.json) covers repeated matches, empty input/query, edge spaces, case sensitivity, punctuation, invalid bytes, and the C source's length/count limits. The existing `i64_array_bytes_output` runner accepts up to 4,096 signed 64-bit input values and 400,004 output bytes; the maximum packed case uses 1,050 input values and the output is 16 bytes.

Build and run with:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm word_count --language rust --with-checker
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/w/word_count/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/w/word_count.c`](../../../c/w/word_count.c) |
| C3 | [`c3/w/word_count.c3`](../../../c3/w/word_count.c3) |
| C++ | [`cpp/w/word_count.cpp`](../../../cpp/w/word_count.cpp) |
| Elisa | [`elisa/w/word_count.elisa`](../../../elisa/w/word_count.elisa) |
| Nim | [`nim/w/word_count.nim`](../../../nim/w/word_count.nim) |
| Odin | [`odin/w/word_count.odin`](../../../odin/w/word_count.odin) |
| Rust | [`rust/w/word_count.rs`](../../../rust/w/word_count.rs) |
| V | [`v/w/word_count.v`](../../../v/w/word_count.v) |
| Zig | [`zig/w/word_count.zig`](../../../zig/w/word_count.zig) |

## Pinned sources

- [C `word_count.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/exercism/word_count/word_count.c)
- [C `word_count.h`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/exercism/word_count/word_count.h)
- [Julia `word_count.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/strings/word_count.jl)
