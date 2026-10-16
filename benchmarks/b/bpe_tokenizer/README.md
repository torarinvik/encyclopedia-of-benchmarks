# Byte-pair encoding tokenizer

This benchmark measures the byte-pair encoding (BPE) merge loop from the pinned TheAlgorithms/Python [`Tokenizer`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/bpe_tokenizer.py). It covers tokenization after text has already been encoded as UTF-8 bytes; text conversion and decoding are outside the measured operation.

## Input and output

Input is a signed 64-bit array `[merge_count, byte_count, byte...]`. It contains 0..512 input bytes and requests 0..32 merge steps. The implementation counts consecutive token pairs on each step, selects the most frequent pair, resolves ties by the pair's first appearance, and replaces non-overlapping occurrences from left to right. New token IDs are `256 + step`, matching the pinned source. When every pair occurs once, further source iterations cannot change the output, so ports stop early.

The return value is the token count. Output is the token IDs encoded as little-endian unsigned 16-bit values. Malformed input or insufficient output capacity returns `-2`. This explicit byte and tie-order contract makes results consistent across languages and machines.

## Workloads

The workload covers empty and single-byte input, repeated and overlapping pairs, first-seen frequency ties, multiple merge levels, zero and maximum merge requests, every byte value, malformed bounds, and insufficient output capacity.
