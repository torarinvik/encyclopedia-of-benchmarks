# Count and Say

This benchmark returns the nth term of the count-and-say sequence. Starting from `1`, each next term describes each maximal run of equal digits in the previous term as its run length followed by the digit.

## Contract

- The input is a one-based term index from 1 through 19. Other values return `-1`.
- Output is the term's ASCII digits without a NUL terminator; the return value is the byte length.
- Insufficient output capacity returns `-2` before writing output.
- The benchmark bounds the index at 19 so the largest supported term fits within the scalar byte-output ABI's 256-byte result buffer; term 19 is 226 bytes.
- Ports generate terms into bounded scratch buffers, then copy the selected term to the caller's output buffer.

The workload includes the first five terms, later sequence terms, the maximum supported index, and invalid boundary values. Build and record the nine implementations with the `i64_scalar_bytes_output` ABI family and `benchmarks/run_i64_scalar_bytes_output.py`.

## Upstream reference

- [TheAlgorithms/C LeetCode 38 at the pinned catalog revision](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/38.c)
