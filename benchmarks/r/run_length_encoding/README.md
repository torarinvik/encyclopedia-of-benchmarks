# Run-length encoding

This benchmark groups adjacent equal ASCII bytes and writes each run as its decimal count followed by its byte. The count-prefixed form follows the string encoding used by some upstream examples and gives the tuple-based variants the same output contract.

## Contract

- Input is a sequence of 0 through 66 signed 64-bit values. Each byte must be in `1..127`, and ASCII decimal digits are excluded so the count and symbol stream remains unambiguous.
- Each run emits one or two decimal count bytes, then the run's original byte. Runs remain separate when the same symbol appears again after another symbol.
- Empty input produces empty output. Invalid input returns `-1`; insufficient output capacity returns `-2`. Errors leave the output buffer untouched.
- The benchmark uses fixed ASCII byte values and portable integer arithmetic.

## Workload and verification

[`workload.json`](workload.json) covers empty and singleton input, alternating symbols, repeated runs, multi-digit counts, control and high ASCII bytes, invalid decimal symbols, and the maximum input length. [`benchmarks/verify_run_length_encoding.py`](../../verify_run_length_encoding.py) checks all valid ASCII symbols, exhaustive short patterns, seeded arrays, invalid inputs, and insufficient output capacity in all nine target languages.

## Reviewed TheAlgorithms sources

The pinned [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/misc/run_length_encoding.c), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/compression/RunLengthEncoding.java), and [Rust string variant](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/string/run_length_encoding.rs) emit count-prefixed text. The [Clojure](https://github.com/TheAlgorithms/Clojure/blob/a9c5bec14928cb22fd4d69e951edf5bd15e16a18/src/data_structures/lists/run_length_encoding.clj), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_compression/run_length_encoding.py), and [Rust tuple variant](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/compression/run_length_encoding.rs) return count/symbol pairs. The benchmark standardizes these result representations to one byte stream; its ASCII and nondigit restrictions make that stream unambiguous.
