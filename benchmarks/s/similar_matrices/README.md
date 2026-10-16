# Similar Matrices

This package benchmarks the pinned [TheAlgorithms/Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/matrix/similar_matrices.py). It compares the exact eigenvalue-to-sorted-Jordan-block-size signatures used by `are_similar_matrices`. Integer entries are unchanged by the source's default `nsimplify` step.

The bounded input is `[n, A row-major, B row-major]`, where both matrices are `n` by `n`, `1 <= n <= 3`, and every entry is an integer from -5 through 5. The implementation compares characteristic polynomials, then resolves repeated-root Jordan structure using exact ranks of the shifted matrices. This is sufficient for dimensions through three and avoids floating-point eigenvalue comparisons. It returns `1` for similar matrices, `0` otherwise, and `-1` for malformed or out-of-domain input. The largest input contains 19 signed-i64 values (152 packed bytes).

See [`workload.json`](workload.json) for cases and bounds. The independent oracle is [`similar_matrices_oracle.py`](../../similar_matrices_oracle.py).
