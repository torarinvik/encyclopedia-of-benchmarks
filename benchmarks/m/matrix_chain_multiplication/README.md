# Matrix-chain multiplication

Matrix-chain multiplication dynamic programming finds the parenthesization that minimizes scalar multiplications for a sequence of matrices. The input dimensions `[d0, d1, ..., dn]` represent matrices `d0×d1`, `d1×d2`, through `d(n-1)×dn`; the matrices are not actually multiplied.

## Contract

- Input contains zero to 65 positive dimensions, each from 1 through 1,000. It represents at most 64 matrices.
- Return the minimum scalar multiplication count. Fewer than two dimensions return zero. Invalid dimensions or an input longer than 65 return `-1`.
- The implementation uses bottom-up dynamic programming with a fixed 65×65 table; the active recurrence takes O(n³) time and stores O(n²) costs for `n` matrices.
- The dimension and matrix-count limits keep every intermediate count within signed 64-bit range.

## Reviewed TheAlgorithms sources

The pinned C++ source uses a memoized recursive recurrence with a small fixed table. Python includes both tabulation and cached-recursive implementations. The shared contract uses bottom-up tabulation and makes the input bounds explicit; Java, Kotlin, and R sources are also included in the candidate inventory.

- [C++ — `matrix_chain_multiplication.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/dynamic_programming/matrix_chain_multiplication.cpp)
- [C++-1 — `matrix_chain_multiplication.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/dynamic_programming/matrix_chain_multiplication.cpp)
- [Java — `MatrixChainMultiplication.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/MatrixChainMultiplication.java)
- [Kotlin — `MatrixChainMultiplication.kt`](https://github.com/TheAlgorithms/Kotlin/blob/b913c1d85c972fd1e679c5d832d6458b21be8fb0/src/main/kotlin/dynamicProgramming/MatrixChainMultiplication.kt)
- [Python — `matrix_chain_multiplication.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/matrix_chain_multiplication.py)
- [R — `matrix_chain_multiplication.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/dynamic_programming/matrix_chain_multiplication.r)

## Workload

`workload.json` covers empty and short chains, known examples, invalid dimensions, and deterministic chains up to 64 matrices. Build and record with the `i64_array_scalar` ABI family. The nine portable source files are under `m/` in each target language folder.
