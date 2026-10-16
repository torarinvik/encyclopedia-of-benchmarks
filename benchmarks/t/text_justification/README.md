# Text justification

This benchmark ports TheAlgorithms/Python's greedy `text_justification` function. It packs words in input order until the next word does not fit. Non-final lines distribute spaces evenly between words, assigning any remainder to the leftmost gaps. The final line is left justified. The pinned routine's empty-text behavior is preserved: it returns one line containing `max_width + 1` spaces.

## Contract

- The `i64_array_bytes_output` input is `[max_width, text_byte_length, ASCII text bytes...]`.
- `max_width` is 1 through 64. Text is 0 through 512 bytes, contains only ASCII spaces and printable non-space ASCII bytes, has at most 64 words, and each word fits within `max_width`. Only ASCII spaces delimit words in this bounded domain; repeated, leading, and trailing spaces collapse as Python's `str.split()` does.
- The output encodes the returned list of lines as ASCII bytes separated by LF (`0x0a`), with no terminal LF. Line padding spaces are part of the output. Empty text produces the pinned `max_width + 1` spaces.
- Malformed inputs return `-1`. Insufficient output capacity returns `-2` without writing. Successful calls return the encoded output byte length. The 4,160-byte workspace covers at most 64 lines of width 64, LF separators, and the pinned routine's extra final space.

The input is bounded to printable ASCII so byte lengths, Python character counts, and all nine ports have the same meaning. Inputs outside that domain are invalid.

## Pinned source

- Python [`text_justification.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/text_justification.py), commit `e1a2a8b016001309a73d5fec4818c35cca139795`.

The independent oracle is [`text_justification_oracle.py`](../../text_justification_oracle.py). The workload includes both pinned examples, greedy wrapping, left-biased extra spaces, whitespace collapsing, empty text, malformed inputs, and insufficient capacity.

Build and record with the byte-output ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm text_justification --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/t/text_justification/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm text_justification
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/text_justification.c`](../../../c/t/text_justification.c) |
| C3 | [`c3/text_justification.c3`](../../../c3/t/text_justification.c3) |
| C++ | [`cpp/text_justification.cpp`](../../../cpp/t/text_justification.cpp) |
| Elisa | [`elisa/text_justification.elisa`](../../../elisa/t/text_justification.elisa) |
| Nim | [`nim/text_justification.nim`](../../../nim/t/text_justification.nim) |
| Odin | [`odin/text_justification.odin`](../../../odin/t/text_justification.odin) |
| Rust | [`rust/text_justification.rs`](../../../rust/t/text_justification.rs) |
| V | [`v/text_justification.v`](../../../v/t/text_justification.v) |
| Zig | [`zig/text_justification.zig`](../../../zig/t/text_justification.zig) |
