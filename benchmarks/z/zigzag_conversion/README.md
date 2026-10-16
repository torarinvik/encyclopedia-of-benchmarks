# ZigZag Conversion

This benchmark converts ASCII English letters to the ZigZag row order used by LeetCode 6. It visits each row and alternates the vertical and diagonal gaps for interior rows, then concatenates those rows.

## Contract

- Input is a signed 64-bit array whose first value is the row count and whose remaining values are ASCII uppercase or lowercase English letters.
- Row counts must be from 1 through 1,024; text length may be from 0 through 1,024 bytes. Invalid inputs return `-1`.
- The output is the original bytes placed into a ZigZag pattern and read row by row. The return value is the output byte length.
- A row count of one, an empty string, or a row count greater than or equal to the text length leaves the text unchanged.
- Insufficient output capacity returns `-2` before writing output.
- Runtime is O(n) and the ports use O(1) extra state beyond the output buffer.

The input array is length-prefixed by the shared C ABI; it does not rely on NUL termination. The workload records the two canonical examples, edge rows, maximum input length, and invalid row/byte values.

## Implementations

Portable implementations use `c/`, `c3/`, `cpp/`, `elisa/`, `nim/`, `odin/`, `rust/`, `v/`, and `zig/`, with the `i64_array_bytes_output` ABI family. Build and record them with `benchmarks/build_abi.py` and `benchmarks/run_i64_array_bytes_output.py`.

## Upstream reference

- [TheAlgorithms/C LeetCode 6 at the pinned catalog revision](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/6.c)
- [TheAlgorithms/Go Rail Fence encryption at the pinned catalog revision](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/cipher/railfence/railfence.go) and [TheAlgorithms/Java Rail Fence encryption](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/RailFenceCipher.java) use the same zigzag placement and row concatenation. Their decryption routines are outside this contract.
