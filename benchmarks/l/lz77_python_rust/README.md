# Python and Rust LZ77 compression

This contract covers the common deterministic compression behavior of the pinned Python and Rust `LZ77Compressor` implementations. Both use their 13/6 defaults, emit `(offset, length, indicator)` triples, update to the later search-buffer position on equal-length matches, and extend overlapping matches recursively. The accepted input is restricted to the shared ASCII domain described below.

## Contract

Input is `[n, character_code_0, ..., character_code_(n-1)]`, with `n` from 0 through 64 and each character code in printable ASCII `[32,126]`. For nonempty input, the final character must occur exactly once in the entire input. The input length is exactly `1+n`; one additional word is parseable for a malformed-frame case.

The compressor uses `window_size=13` and `lookahead_buffer_size=6`, which produce a search-buffer capacity of seven characters. In these sources, the lookahead argument sets that capacity but does not impose a six-character match limit. A match may extend beyond six characters by overlapping the input. Search-buffer positions are examined from oldest to newest; on equal match lengths, the later position replaces the earlier one, choosing the smaller offset. Each token stores `(offset, length, indicator)` and consumes `length+1` characters. The search buffer is updated with those consumed characters and trimmed to its last seven characters.

The two pinned implementations agree on this bounded input. Printable ASCII makes Python character lengths and Rust UTF-8 byte lengths equal. The globally unique final character prevents a candidate from matching the entire remaining suffix: Python would otherwise index past the end when selecting `text[length]`, while Rust clamps that match to leave an indicator. Under this restriction the Python error case cannot occur and the Rust clamp never changes a match length, so both sources emit the same token records. Empty input is valid and emits no records.

Output is a sequence of little-endian signed-i64 triples `(offset, length, indicator)` with no count prefix. A successful call returns the number of bytes written; the maximum is 1536 bytes. The benchmark covers `compress` only; `decompress` is outside the operation. Malformed framing, unsupported characters, or a repeated final character return `-1` before output checks. A null output pointer or capacity below the encoded result size returns `-2`; errors write no bytes.

The independent oracle is [`../../lz77_python_rust_oracle.py`](../../lz77_python_rust_oracle.py). The workload includes overlapping matches, a tie that selects the smaller offset, matches longer than six characters, the final-character common-domain rule, maximum output, malformed input, and output-capacity cases.

## Language ports

| Language | Source |
| --- | --- |
| C | [lz77_python_rust.c](../../../c/l/lz77_python_rust.c) |
| C3 | [lz77_python_rust.c3](../../../c3/l/lz77_python_rust.c3) |
| C++ | [lz77_python_rust.cpp](../../../cpp/l/lz77_python_rust.cpp) |
| Elisa | [lz77_python_rust.elisa](../../../elisa/l/lz77_python_rust.elisa) |
| Nim | [lz77_python_rust.nim](../../../nim/l/lz77_python_rust.nim) |
| Odin | [lz77_python_rust.odin](../../../odin/l/lz77_python_rust.odin) |
| Rust | [lz77_python_rust.rs](../../../rust/l/lz77_python_rust.rs) |
| V | [lz77_python_rust.v](../../../v/l/lz77_python_rust.v) |
| Zig | [lz77_python_rust.zig](../../../zig/l/lz77_python_rust.zig) |

## Pinned sources

- TheAlgorithms/Python [`lz77.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_compression/lz77.py), `LZ77Compressor` with default sizes.
- TheAlgorithms/Rust [`lz77.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/compression/lz77.rs), `LZ77Compressor::default()`.
