# Word occurrence

This benchmark follows the pinned Python `word_occurrence` function, which counts each exact token from `sentence.split()` and returns a case-sensitive mapping. It is distinct from [`check_word_occurrence`](../check_word_occurrence/README.md): that JavaScript source preserves leading and trailing empty fields and exposes a flag that reverses the apparent case-sensitivity behavior.

## Contract

- Input is `[byte_length, bytes...]`, with 0 through 1,024 ASCII bytes in `0..127`. Python's ASCII whitespace set is bytes 9 through 13, 28 through 32. Runs of whitespace split tokens; leading and trailing whitespace produce no empty token.
- Tokens are case-sensitive, and punctuation, NUL, and other non-whitespace ASCII bytes remain part of a token. Empty input or whitespace-only input returns an empty mapping.
- Output is a binary map: a little-endian u32 entry count, followed in first-occurrence order by each key's u32 byte length, raw key bytes, and u32 frequency. The function returns the encoded byte length, `-1` for malformed packed input or non-ASCII bytes, and `-2` when the output buffer is too small. The 8,192-byte workspace covers the maximum map for the input bound.
- The pinned F# file has a defect: it adds a key with value 1, then prints duplicates instead of incrementing their counts. It is not equivalent to the Python counting source and is tracked separately by the catalog owner rather than included as a matching port.

[`workload.json`](workload.json) covers empty and whitespace-only input, case distinctions, repeated whitespace, punctuation, Python's ASCII control whitespace, embedded NUL, insertion order, the 1,024-byte boundary, malformed inputs, and output capacity. The independent oracle is [`word_occurrence_oracle.py`](../../word_occurrence_oracle.py).

## Pinned source

- Python [`word_occurrence.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/word_occurrence.py) splits on whitespace, increments a `defaultdict(int)`, and preserves token case.
- F# [`WordOccurrence.fs`](https://github.com/TheAlgorithms/F-Sharp/blob/e5441e8bfd2cda87541634b75f39f0868447ae5f/Algorithms/Strings/WordOccurrence.fs) is recorded as a separate invalid variant because its duplicate branch only prints.

## Build and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm word_occurrence --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm word_occurrence
```

Run the full oracle and workload checks with python3 benchmarks/verify_i64_array_bytes_output.py --algorithm word_occurrence.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/w/word_occurrence.c`](../../../c/w/word_occurrence.c) |
| C3 | [`c3/w/word_occurrence.c3`](../../../c3/w/word_occurrence.c3) |
| C++ | [`cpp/w/word_occurrence.cpp`](../../../cpp/w/word_occurrence.cpp) |
| Elisa | [`elisa/w/word_occurrence.elisa`](../../../elisa/w/word_occurrence.elisa) |
| Nim | [`nim/w/word_occurrence.nim`](../../../nim/w/word_occurrence.nim) |
| Odin | [`odin/w/word_occurrence.odin`](../../../odin/w/word_occurrence.odin) |
| Rust | [`rust/w/word_occurrence.rs`](../../../rust/w/word_occurrence.rs) |
| V | [`v/w/word_occurrence.v`](../../../v/w/word_occurrence.v) |
| Zig | [`zig/w/word_occurrence.zig`](../../../zig/w/word_occurrence.zig) |
