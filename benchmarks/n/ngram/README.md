# N-gram windows

Generate every contiguous substring of the requested width, preserving source order and duplicate windows. The pinned Python source returns a list; this benchmark serializes that list as ASCII windows separated by one newline byte. Inputs exclude newline so the serialization is unambiguous.

## Contract

- The `i64_array_bytes_output` input is `[ngram_size, text_length, character_code_0, ..., character_code_n-1]`.
- Width is 1 through 16, length is 0 through 256, and each character is printable ASCII (32 through 126).
- The output contains left-to-right windows joined by newline. If width exceeds text length, output is empty. The return value is bytes written; malformed input returns -1 and insufficient capacity returns -2.

[`workload.json`](workload.json) contains the source example, edge cases, malformed inputs, and maximum text length.

## Implementations

- C: [`c/n/ngram.c`](../../../c/n/ngram.c)
- C3: [`c3/n/ngram.c3`](../../../c3/n/ngram.c3)
- C++: [`cpp/n/ngram.cpp`](../../../cpp/n/ngram.cpp)
- Elisa: [`elisa/n/ngram.elisa`](../../../elisa/n/ngram.elisa)
- Nim: [`nim/n/ngram.nim`](../../../nim/n/ngram.nim)
- Odin: [`odin/n/ngram.odin`](../../../odin/n/ngram.odin)
- Rust: [`rust/n/ngram.rs`](../../../rust/n/ngram.rs)
- V: [`v/n/ngram.v`](../../../v/n/ngram.v)
- Zig: [`zig/n/ngram.zig`](../../../zig/n/ngram.zig)

The source is [TheAlgorithms/Python `strings/ngram.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/ngram.py).
