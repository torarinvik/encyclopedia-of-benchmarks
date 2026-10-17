# Lempel–Ziv Decompression

This benchmark calls the pinned in-memory `decompress_data` routine on a
bounded ASCII bit string. It excludes file reading, the gamma-coded file-size
prefix, prefix removal, and byte padding/writing. Semantic workload streams
are produced by the pinned companion `compress_data` routine; their decoded
results are the output of the pinned decompressor, including its source-specific
behavior.

## Input and output

The ABI is `i64_array_bytes_output`. Input is
`[bit_count, ascii_bit_0, ..., ascii_bit_(bit_count-1)]`, where ASCII `0` and
`1` are the integer values 48 and 49. `bit_count` is an exact integer in
`[0, 128]`, and the packed input contains exactly `1 + bit_count` signed
64-bit integers. Any other data byte is invalid.

The output is the decompressed string as raw ASCII bytes, each byte being
`0` or `1`. The source decoder emits a matched dictionary expansion and resets
its pending prefix after every match; a final unmatched prefix is discarded.
It starts with `{"0": "0", "1": "1"}`, appends `last_match + "0"` to the
matched entry, rebuilds the keys with a leading `0` when
`math.log2(index).is_integer()`, inserts `bin(index)[2:] -> last_match + "1"`,
then increments the index. Preserve this operation order and Python dictionary
insertion order during rebuilds.

For at most `L` input bits, there can be at most `L` matches. The expansion
emitted by match `j` is at most `j` bits, so the output is bounded by
`L*(L+1)/2`, or 8,256 bytes at the maximum input length. The benchmark accepts
the source's bounded bit-string behavior; it does not claim that this
implementation is a general lossless file codec.

Malformed framing or a non-bit byte returns `-1`. A null output pointer or
capacity below the decoded byte count returns `-2` after input validation and
without writes. Output bytes are compared exactly.

## Pinned sources

The decoder is TheAlgorithms/Python
[`lempel_ziv_decompress.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_compression/lempel_ziv_decompress.py),
commit `e1a2a8b016001309a73d5fec4818c35cca139795`, function `decompress_data`.
Fixture bit streams come from the pure `compress_data` function in the
companion
[`lempel_ziv.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_compression/lempel_ziv.py)
at the same commit. The workload and independent decoder oracle are
[`workload.json`](workload.json) and
[`benchmarks/lempel_ziv_decompress_oracle.py`](../../lempel_ziv_decompress_oracle.py).
