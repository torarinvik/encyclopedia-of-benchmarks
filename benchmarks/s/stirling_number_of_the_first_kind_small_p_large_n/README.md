# Signed Stirling numbers of the first kind: small prime, large n

## Contract

The official task asks for signed s(n,k) modulo a shared prime p for T
queries, with T<=200000, p<=5000, and n<=10^18. This local
`i64_array_scalar` profile accepts `[T,p,n0,k0,...]`, restricts T to 1..8,
p to primes 11..97, and each k to 0..8 with k<=n<=10^18. It returns
`sum((i+1)^2*s(ni,ki)) mod p`. The checksum is not injective and does not
replace the official per-query output. Invalid frames return -1.

## Residue-block kernel

The official definition is the coefficient identity
`product(x-i, i=0..n-1) = sum(s(n,k)*x^k)`. Write n=qp+r, with 0<=r<p.
Modulo p, every block of p consecutive residues contributes
`product(x-a, a=0..p-1) = x^p-x`, since both sides are monic degree-p
polynomials with the elements of F_p as their roots. Therefore

`product(x-i, i=0..n-1) = (x^p-x)^q * product(x-a, a=0..r-1)`.

The first factor has minimum degree q, so every coefficient with k<q is
zero. Here p>=11 and k<=8, so p-1>k: every term in the block-power
expansion that chooses x^p has degree at least q+p-1>k. Only `(-x)^q`
contributes, giving `s(n,k)=(-1)^q * [x^(k-q)]R_r` when q<=k. The ports
build R_r only through the needed degree. Work is O(pk) when q<=k and O(1)
when q>k, independent of large n.

The workload includes recurrence-consistent edge checks: s(0,0)=1,
s(3,2)=-3, s(p,1)=-1, and s(p+1,2)=-1 modulo p.

The primary oracle implements the reduced coefficient rule. The verifier
oracle independently raises the truncated polynomial x^p-x to q by binary
polynomial exponentiation, then multiplies by the remainder polynomial.
Both cover the full local input domain including n up to 10^18.

## Local comparison and source

The ordinary first-kind full-row and fixed-k tasks use the same signed
coefficient recurrence; the second-kind fixed-k task selects a column from
its triangle recurrence. Those are triangle-DP or output variants. The
existing `stirling_number_of_the_second_kind` profile computes a full row
only through N<=16. The S2 small-p/large-n profile uses matrix exponentiation
for the second-kind recurrence; it does not compute signed first-kind
coefficients by residue blocks. `bell_numbers` returns a row sum and integer
partition packages count a different object. None duplicates this signed
large-n coefficient kernel.

Official statement: [Library Checker — Stirling Number of the First Kind
(Small p, Large n)](https://github.com/yosupo06/library-checker-problems/blob/master/enumerative_combinatorics/stirling_number_of_the_first_kind_small_p_large_n/task.md).
Official bounds: [info.toml](https://github.com/yosupo06/library-checker-problems/blob/master/enumerative_combinatorics/stirling_number_of_the_first_kind_small_p_large_n/info.toml).
The official task data lists `naive.cpp` with `allow_tle=true` and gives no
efficient algorithm. The residue-block factorization is derived directly
from the task's signed falling-factorial identity. All implementations,
oracles, fixtures, and explanatory prose here are clean-room work. See
[RIGHTS.md](RIGHTS.md).

## Workload and ports

[`workload.json`](workload.json) records checksums and profile bounds.
[`verify_workload.py`](verify_workload.py) compares both oracles against each
fixture and checks all ten source paths. The profile is registered with the
`i64_array_scalar` runner and verifier; neither was run during this write-only
integration.

| Language | Source |
|---|---|
| C | [c/s/stirling_number_of_the_first_kind_small_p_large_n.c](../../../c/s/stirling_number_of_the_first_kind_small_p_large_n.c) |
| C3 | [c3/s/stirling_number_of_the_first_kind_small_p_large_n.c3](../../../c3/s/stirling_number_of_the_first_kind_small_p_large_n.c3) |
| C++ | [cpp/s/stirling_number_of_the_first_kind_small_p_large_n.cpp](../../../cpp/s/stirling_number_of_the_first_kind_small_p_large_n.cpp) |
| Elisa | [elisa/s/stirling_number_of_the_first_kind_small_p_large_n.elisa](../../../elisa/s/stirling_number_of_the_first_kind_small_p_large_n.elisa) |
| Mojo | [mojo/s/stirling_number_of_the_first_kind_small_p_large_n.mojo](../../../mojo/s/stirling_number_of_the_first_kind_small_p_large_n.mojo) |
| Nim | [nim/s/stirling_number_of_the_first_kind_small_p_large_n.nim](../../../nim/s/stirling_number_of_the_first_kind_small_p_large_n.nim) |
| Odin | [odin/s/stirling_number_of_the_first_kind_small_p_large_n.odin](../../../odin/s/stirling_number_of_the_first_kind_small_p_large_n.odin) |
| Rust | [rust/s/stirling_number_of_the_first_kind_small_p_large_n.rs](../../../rust/s/stirling_number_of_the_first_kind_small_p_large_n.rs) |
| V | [v/s/stirling_number_of_the_first_kind_small_p_large_n.v](../../../v/s/stirling_number_of_the_first_kind_small_p_large_n.v) |
| Zig | [zig/s/stirling_number_of_the_first_kind_small_p_large_n.zig](../../../zig/s/stirling_number_of_the_first_kind_small_p_large_n.zig) |
