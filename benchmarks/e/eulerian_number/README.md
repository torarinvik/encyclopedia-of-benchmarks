# Eulerian number by descent count

This benchmark returns one entry of the classical Eulerian triangle. For
`n>=1`, `A(n,k)` counts permutations of `[n]` that have exactly `k` descents,
where a descent is an adjacent pair `p[i] > p[i+1]`. The empty permutation
has the explicit base value `A(0,0)=1`.

## Contract

- ABI: `i64_array_scalar`, input `[n,k]`.
- Accept `0<=n<=20`; for `n=0`, only `k=0` is valid. For positive `n`, accept
  `0<=k<n`.
- Return the exact count `A(n,k)`. Invalid input or malformed/null framing
  returns `-1`.
- Every result is bounded by `20! = 2432902008176640000`, which fits in
  signed 64-bit output.
- The primary builds each row with
  `A(n,k)=(k+1)A(n-1,k)+(n-k)A(n-1,k-1)`, treating out-of-range entries as
  zero. It takes `O(n^2)` time and `O(n)` auxiliary storage.
- The independent reference uses the inclusion-exclusion expression
  `A(n,k)=sum(j=0..k+1, (-1)^j * binom(n+1,j) * (k+1-j)^n)` for `n>=1` with
  arbitrary-precision intermediates. It returns `A(0,0)=1` directly.

## Distinction and provenance

The repository's [`entringer_number`](../entringer_number/README.md) computes
the Entringer triangle, grouping alternating permutations by their first
element. Eulerian numbers instead count ordinary permutations by descents.
Eulerian paths and Eulerian circuits concern graph traversal and are separate
algorithms.

The discovery heading is OI Wiki's “Eulerian Number” article in its current
[algorithm navigation](https://github.com/OI-wiki/OI-wiki/blob/master/mkdocs.yml).
Method context is the [OI Wiki article](https://oi-wiki.org/math/combinatorics/eulerian/),
Stanley's *Enumerative Combinatorics*, Volume 1, §1.4, and the classical
[Eulerian triangle A008292](https://oeis.org/A008292). OI Wiki states
[CC BY-SA 4.0 and SATA](https://oi-wiki.org/intro/faq/); this package uses the
mathematical method idea only. No OI Wiki code, prose, examples, or test cases
are copied.

[`workload.json`](workload.json) pins the base case, symmetric row entries,
maximum `n`, malformed frames, and out-of-domain values. The package-local
`verify_workload.py` cross-checks fixtures using both references, and
`check_inventory.py` checks the ten native ports and package artifacts. No
programs, scripts, or checkers have been run.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/e/eulerian_number.c](../../../c/e/eulerian_number.c) |
| C3 | [c3/e/eulerian_number.c3](../../../c3/e/eulerian_number.c3) |
| C++ | [cpp/e/eulerian_number.cpp](../../../cpp/e/eulerian_number.cpp) |
| Elisa | [elisa/e/eulerian_number.elisa](../../../elisa/e/eulerian_number.elisa) |
| Mojo | [mojo/e/eulerian_number.mojo](../../../mojo/e/eulerian_number.mojo) |
| Nim | [nim/e/eulerian_number.nim](../../../nim/e/eulerian_number.nim) |
| Odin | [odin/e/eulerian_number.odin](../../../odin/e/eulerian_number.odin) |
| Rust | [rust/e/eulerian_number.rs](../../../rust/e/eulerian_number.rs) |
| V | [v/e/eulerian_number.v](../../../v/e/eulerian_number.v) |
| Zig | [zig/e/eulerian_number.zig](../../../zig/e/eulerian_number.zig) |

The package is registered in the `i64_array_scalar` runner and verifier and in
the root catalog. No programs, scripts, checkers, tests, builds, compilers, or
benchmarks have been run.
