# Stirling numbers of the second kind: small prime, large n

## Contract

The official task asks for S(n,k) modulo a shared prime p for T queries, with
T<=200000, p<=5000, and n<=10^18. This local `i64_array_scalar` profile
accepts `[T,p,n0,k0,...]`, restricts T to 1..8, p to primes 11..97, and each
k to 0..8 with k<=n<=10^18. It computes each requested value and returns
`sum((i+1)^2*S(ni,ki)) mod p`. The checksum is not injective and does not
replace the official per-query output. Invalid frames return -1.

The profile uses the recurrence
`S(n+1,j)=j*S(n,j)+S(n,j-1)`. For a fixed requested k, the values for
j=0..k form a k+1 state vector. The ports exponentiate its lower-bidiagonal
transition matrix by n, so the number of steps grows logarithmically with n.
The bounded matrix calculation costs O(k^3 log n) time and O(k^2) workspace.
This is a different kernel from building a complete row with the S2 package's
O(N^2) triangle recurrence.

The bound p>k makes k! invertible modulo p. The primary oracle uses the same
matrix-power formulation; an independent oracle evaluates the
inclusion-exclusion formula
`S(n,k)=1/k! * sum((-1)^(k-j) C(k,j) j^n, j=0..k)` in the finite field.

## Comparison with local packages

The ordinary first-kind full-row task changes the coefficient recurrence's
sign and multiplier. The first-kind fixed-k and second-kind fixed-k tasks
select a column prefix from those same triangle recurrences. Those are
output or coefficient-family variants rather than new kernels. Local
`bell_numbers` uses Bell's triangle and returns the sum of a Stirling row as
one Bell number, and
`partitions` / `integer_partition` count unordered integer-sum partitions;
none implements large-n fixed-k Stirling evaluation. This profile's
matrix-exponentiation kernel supports n up to 10^18 at a small fixed k.

## Sources and rights

Official statement: [Library Checker — Stirling Number of the Second Kind
(Small p, Large n)](https://github.com/yosupo06/library-checker-problems/blob/master/enumerative_combinatorics/stirling_number_of_the_second_kind_small_p_large_n/task.md).
Official bounds: [info.toml](https://github.com/yosupo06/library-checker-problems/blob/master/enumerative_combinatorics/stirling_number_of_the_second_kind_small_p_large_n/info.toml).
The official repository identifies the problem collection under Apache-2.0.
The ports and oracles here are clean-room implementations; no upstream code
or prose is copied. See [RIGHTS.md](RIGHTS.md).

## Workload and ports

[`workload.json`](workload.json) records the checksum fixtures and profile
bounds. [`verify_workload.py`](verify_workload.py) compares fixtures with the
matrix primary oracle and independent inclusion-exclusion oracle, and checks
the ten source paths. The workload is registered with the `i64_array_scalar`
runner and verifier; neither was run during this write-only integration.

| Language | Source |
|---|---|
| C | [c/s/stirling_number_of_the_second_kind_small_p_large_n.c](../../../c/s/stirling_number_of_the_second_kind_small_p_large_n.c) |
| C3 | [c3/s/stirling_number_of_the_second_kind_small_p_large_n.c3](../../../c3/s/stirling_number_of_the_second_kind_small_p_large_n.c3) |
| C++ | [cpp/s/stirling_number_of_the_second_kind_small_p_large_n.cpp](../../../cpp/s/stirling_number_of_the_second_kind_small_p_large_n.cpp) |
| Elisa | [elisa/s/stirling_number_of_the_second_kind_small_p_large_n.elisa](../../../elisa/s/stirling_number_of_the_second_kind_small_p_large_n.elisa) |
| Mojo | [mojo/s/stirling_number_of_the_second_kind_small_p_large_n.mojo](../../../mojo/s/stirling_number_of_the_second_kind_small_p_large_n.mojo) |
| Nim | [nim/s/stirling_number_of_the_second_kind_small_p_large_n.nim](../../../nim/s/stirling_number_of_the_second_kind_small_p_large_n.nim) |
| Odin | [odin/s/stirling_number_of_the_second_kind_small_p_large_n.odin](../../../odin/s/stirling_number_of_the_second_kind_small_p_large_n.odin) |
| Rust | [rust/s/stirling_number_of_the_second_kind_small_p_large_n.rs](../../../rust/s/stirling_number_of_the_second_kind_small_p_large_n.rs) |
| V | [v/s/stirling_number_of_the_second_kind_small_p_large_n.v](../../../v/s/stirling_number_of_the_second_kind_small_p_large_n.v) |
| Zig | [zig/s/stirling_number_of_the_second_kind_small_p_large_n.zig](../../../zig/s/stirling_number_of_the_second_kind_small_p_large_n.zig) |
