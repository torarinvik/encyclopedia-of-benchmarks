# A1Z26 encoding

This benchmark maps each ASCII English letter to its one-based alphabet position: `a/A = 1` through `z/Z = 26`. It returns the positions as raw bytes, which represent the numeric sequence directly and avoid formatting differences between source APIs.

## Contract

- Input is a sequence of 0 through 66 ASCII letters in either case. Other values are invalid.
- Output contains one byte per input letter, with values from 1 through 26. Letter case does not affect the value.
- Empty input produces empty output. Invalid input returns `-1`; insufficient output capacity returns `-2`. Errors leave the output buffer untouched.

## Workload and verification

[`workload.json`](workload.json) includes the `myname` example, both letter cases, invalid characters, and the maximum input length. [`benchmarks/verify_a1z26.py`](../../verify_a1z26.py) checks both A1Z26 directions against the shared oracle in all nine target languages. The generic byte-output verifier also checks this benchmark with an independent oracle: `python3 benchmarks/verify_i64_array_bytes_output.py --algorithm a1z26_cipher`.

## Reviewed TheAlgorithms sources

The C++ [`a1z26_cipher`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/ciphers/a1z26_cipher.cpp) and [Python `a1z26`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/a1z26.py) sources perform this letter-to-number mapping. The benchmark standardizes their text and list output forms to numeric bytes.
