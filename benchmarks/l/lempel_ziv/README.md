# Lempel–Ziv Compression

This benchmark calls the pinned in-memory `compress_data` routine on a bounded
ASCII bit string. It excludes file reading, the gamma-coded file-size prefix,
and byte stop-bit padding/writing.

## Input and output

The ABI is `i64_array_bytes_output`. Input is
`[bit_count, ascii_bit_0, ..., ascii_bit_(bit_count-1)]`, with ASCII `0` and
`1` represented by integer values 48 and 49. `bit_count` is an exact integer
from 0 through 128, and the packed input contains exactly `1 + bit_count`
signed 64-bit integers. Other data bytes are invalid.

The output is the compressed bit string as raw ASCII bytes. The routine starts
with `{"0": "0", "1": "1"}` and code index 2. For each input bit it extends
the pending string; when that string exists in the lexicon, it appends its
stored code, removes the matched key, and adds `matched + "0"` with the
matched code as its value. At power-of-two indices, it prefixes every current
lexicon value with `0`; it then adds `matched + "1" -> bin(index)[2:]`,
increments the index, and clears the pending string. If the input ends with an
unmatched suffix, the source appends zero bits until the suffix is a lexicon
key and emits that key's code. This benchmark preserves that zero-extension
behavior; it does not add file framing or claim a general lossless codec.

For binary input, the lexicon remains a complete prefix code: each match
replaces one leaf with its `0` and `1` children. The final zero-extension loop
therefore reaches a key for every bit string. The oracle uses a finite
defensive bound around that source loop; it does not change accepted binary
inputs. For at most 128 input bits, there are at most 128 matches and one final
suffix code. Each emitted code is at most 8 bits, so output is bounded by
1,032 bytes.

Malformed framing or non-bit bytes returns `-1`. A null output pointer or
insufficient capacity returns `-2` after input validation and without writes.
Output bytes are compared exactly.

## Pinned source

The source is TheAlgorithms/Python
[`lempel_ziv.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_compression/lempel_ziv.py),
commit `e1a2a8b016001309a73d5fec4818c35cca139795`, function `compress_data`.
The workload and independent oracle are [`workload.json`](workload.json) and
[`benchmarks/lempel_ziv_oracle.py`](../../lempel_ziv_oracle.py).
