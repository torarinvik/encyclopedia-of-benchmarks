# Active algorithm reservation

- **Algorithm:** `batch_gcd_small_range_precomputed`
- **Status:** Implemented in ten languages and registered in the byte-output runner/verifier; static integration review pending.
- **Discovery source:** [Library Checker proposal #1380, O(V)-O(1) gcd](https://github.com/yosupo06/library-checker-problems/issues/1380).
- **Local overlap review:** The existing `gcd` package uses Euclid's remainder loop per pair, while `bitwise_gcd` uses Stein's binary GCD per pair. Neither performs an `O(V)` preprocessing pass that makes each subsequent bounded-range pair query constant time. `gcd_of_n_numbers` folds the ordinary GCD over a list and is also distinct.
- **Method:** Build a linear least-prime-factor table through `V`; recursively store each `x<=V` as three factors, preserving the proposal's invariant that each factor is at most `sqrt(x)` or prime; precompute a triangular Euclidean-GCD table for small remainders; answer each pair by decomposing one operand and combining three table lookups or prime divisibility checks.
- **Planned contract:** `i64_array_bytes_output`, input `[V,Q,(a,b)*Q]`, `1<=V<=64`, `0<=Q<=64`, and `0<=a,b<=V`; emit one little-endian i64 GCD per pair. Handle zero operands directly. Exact maximum sizes and workspace will be pinned in the package README and workload.
- **Planned complexity:** `O(V+Q)` time and `O(V)` auxiliary space for the bounded word model.
- **Rights:** Use the proposal only as an algorithm-idea index. Do not copy its issue text, code, tests, or examples. Cite the proposal and state that the package implementation and fixtures are original.
- **Coverage:** Ten language ports, an independent Euclidean reference, bounded fixtures, byte-output suite registration, and root catalog entries are present. No project execution has been performed.

