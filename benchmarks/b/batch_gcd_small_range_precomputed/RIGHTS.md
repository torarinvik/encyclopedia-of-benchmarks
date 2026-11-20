# Rights and provenance

The method was discovered through the open [Library Checker proposal #1380](https://github.com/yosupo06/library-checker-problems/issues/1380), which proposes an `O(V)` preprocessing pass for a batch of bounded-range GCD queries. The Library Checker problem repository identifies its contents as Apache-2.0, but this benchmark does not reuse repository code, tests, examples, or issue prose. The proposal is treated as an idea index only.

The implementation independently expresses the method using a linear least-prime-factor sieve, three-factor representations, a triangular Euclidean-GCD table, and per-query factor reduction. The package's ABI, bounds, fixtures, references, and documentation are original. The independent oracle uses ordinary Euclid and does not reproduce the precomputation method.
