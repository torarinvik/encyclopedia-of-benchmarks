# A1Z26 decoding

This benchmark maps each one-based alphabet position from 1 through 26 to its lowercase ASCII letter. It returns the decoded letters as raw bytes.

## Contract

- Input is a sequence of 0 through 66 integers from 1 through 26.
- Output contains one lowercase ASCII letter per input value.
- Empty input produces empty output. Invalid input returns `-1`; insufficient output capacity returns `-2`. Errors leave the output buffer untouched.

## Workload and verification

[`workload.json`](workload.json) covers the `myname` vector, the full alphabet, invalid values, and the maximum input length. [`benchmarks/verify_a1z26.py`](../../verify_a1z26.py) verifies both directions in all nine target languages. The generic byte-output verifier checks this direction independently with `python3 benchmarks/verify_i64_array_bytes_output.py --algorithm a1z26_decipher`.

## Reviewed TheAlgorithms sources

The C++ [`a1z26_cipher`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/ciphers/a1z26_cipher.cpp) and [Python `a1z26`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/a1z26.py) files also contain the inverse letter-number mapping. This benchmark standardizes on integer input values and lowercase ASCII output.
