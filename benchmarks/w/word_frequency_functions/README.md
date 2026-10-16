# Word Frequency Functions

This package preserves the four independently callable routines in the pinned Python `word_frequency_functions.py`. The ABI operation tag selects exactly one routine; term frequency, document frequency, inverse document frequency, and TF-IDF keep their separate input and result semantics.

## Operations and input

Text operations use ASCII byte strings. Their packed input is `[operation, term_length, term_bytes..., text_length, text_bytes...]`.

| Operation | Source routine | Semantics |
| --- | --- | --- |
| `0` | `term_frequency(term, document)` | Delete ASCII punctuation and LF from the document; split on literal ASCII spaces, preserving empty tokens; count exact case-insensitive token matches. |
| `1` | `document_frequency(term, corpus)` | Lowercase and delete ASCII punctuation from the corpus; split on LF, preserving empty documents; count documents containing the lowercased term as a substring. |
| `2` | `inverse_document_frequency(df, n, smoothing)` | Compute `round(log10(n/df), 3)` or, with smoothing, `round(1 + log10(n/(1+df)), 3)`. Source `ZeroDivisionError` and `ValueError` results are represented by output tags. |
| `3` | `tf_idf(tf, idf)` | Compute the source's `round(tf * idf, 3)` with integer `tf` and `idf` represented in thousandths. |

For operation 2 the exact input is `[2, df, n, smoothing]`. `df` and `n` are each 0–1,000,000 and `smoothing` is 0 or 1. For operation 3 the exact input is `[3, tf, idf_milli]`, where `tf` is 0–1,000,000 and `idf_milli` is -1,000,000–1,000,000. Text operations accept terms up to 128 bytes and documents/corpora up to 4,096 bytes; all bytes must be ASCII `0..127`. The packed length must exactly match the selected operation's layout.

## Output

Successful results are binary records beginning with a little-endian u32 result-kind tag, followed by signed little-endian i64 payloads:

- Kind `0`: term-frequency integer count (one i64).
- Kind `1`: document-frequency pair `(matching_document_count, document_count)` (two i64 values).
- Kind `2`: IDF or TF-IDF rounded result as an integer number of thousandths (one i64).
- Kind `3`: source `ZeroDivisionError` from unsmoothed IDF with `df=0` (tag only).
- Kind `4`: source `ValueError` when IDF has `n=0` (tag only).

The function returns the encoded byte length, `-1` for malformed input, and `-2` when the output capacity is insufficient. The maximum successful record is 20 bytes.

The pinned Python source removes punctuation only from the text, not from the term. `term_frequency` splits on a literal space, so repeated, leading, or trailing spaces create empty tokens. `document_frequency` uses substring matching rather than token matching and counts trailing empty lines. These behaviors are covered explicitly in [`workload.json`](workload.json).

## Pinned source

- Python [`word_frequency_functions.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/word_frequency_functions.py) defines all four callable functions independently.

## Build and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm word_frequency_functions --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm word_frequency_functions
```

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/w/word_frequency_functions.c`](../../../c/w/word_frequency_functions.c) |
| C3 | [`c3/w/word_frequency_functions.c3`](../../../c3/w/word_frequency_functions.c3) |
| C++ | [`cpp/w/word_frequency_functions.cpp`](../../../cpp/w/word_frequency_functions.cpp) |
| Elisa | [`elisa/w/word_frequency_functions.elisa`](../../../elisa/w/word_frequency_functions.elisa) |
| Nim | [`nim/w/word_frequency_functions.nim`](../../../nim/w/word_frequency_functions.nim) |
| Odin | [`odin/w/word_frequency_functions.odin`](../../../odin/w/word_frequency_functions.odin) |
| Rust | [`rust/w/word_frequency_functions.rs`](../../../rust/w/word_frequency_functions.rs) |
| V | [`v/w/word_frequency_functions.v`](../../../v/w/word_frequency_functions.v) |
| Zig | [`zig/w/word_frequency_functions.zig`](../../../zig/w/word_frequency_functions.zig) |
