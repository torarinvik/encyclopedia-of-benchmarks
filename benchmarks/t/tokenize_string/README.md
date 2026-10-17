# Tokenize a string

Split an ASCII string at each selected delimiter while preserving empty tokens.
The source is the `stTokenize` routine in
[`string/tokenize_string.s`](https://github.com/TheAlgorithms/AArch64_Assembly/blob/cb138a856a3af14d3d3dfcd2743d43841eec566f/string/tokenize_string.s)
from TheAlgorithms/AArch64_Assembly, pinned at commit
`cb138a856a3af14d3d3dfcd2743d43841eec566f`. The source comments attribute the
implementation to [Rosetta Code's “Tokenize a string”](https://rosettacode.org/wiki/Tokenize_a_string)
under CC BY-SA 4.0. This benchmark isolates the tokenizer routine from the
assembly program's print-and-exit wrapper.

## Contract

The `i64_array_bytes_output` input is
`[length, separator_byte, text_bytes...]`, with exactly `2 + length` values.
The text length is 0..128 bytes, excluding the adapter-added C NUL. Text bytes
are printable ASCII (32..126), and the separator is comma, period, or colon.
At most 18 separator bytes are permitted, yielding at most 19 tokens. This is
the safe limit for the source's table of 20 words: one count word followed by
19 token pointers. The tokenizer preserves empty tokens, including on empty
input and around repeated, leading, or trailing delimiters.

The output is a binary record: one raw byte with the token count, followed by
the copied text with each separator replaced by NUL and one final NUL. Thus
the result is exactly `length + 2` bytes and is at most 130 bytes. Invalid
packing or inputs return `-1`. A null output buffer or capacity below the
required result length returns `-2`; error cases write no output.

[`workload.json`](workload.json) covers the pinned example, empty and
single-token strings, all three delimiters, empty-token boundaries, the
maximum safe text and token bounds, malformed inputs, and output-buffer
errors. The independent oracle is
[`benchmarks/tokenize_string_oracle.py`](../../tokenize_string_oracle.py).

Build and record the Rust port with:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm tokenize_string --language rust --with-checker
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/t/tokenize_string/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm tokenize_string --languages rust
```
