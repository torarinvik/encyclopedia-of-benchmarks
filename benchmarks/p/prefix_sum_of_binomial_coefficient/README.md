# Prefix sum of binomial coefficients

For each query `(N, K)`, compute `C(N,0) + C(N,1) + ... + C(N,K)` modulo
998244353. This is an arbitrary prefix of one row, so the query is different
from returning a single coefficient or the total of the entire row.

## Local comparison

[`sum_of_binomial_coefficient`](../sum_of_binomial_coefficient/README.md)
returns the full-row identity `2^N`; that determines the answer only when
`K=N`. [`binomial_coefficient`](../../b/binomial_coefficient/README.md) returns
one exact coefficient using Pascal-row updates, and
[`binomial_calculate`](../../b/binomial_calculate/README.md) returns one exact
coefficient using an integer multiplicative recurrence. The local Pascal-row
packages build, hash, or return bounded rows; none sums a modular prefix for an
arbitrary `K`.

## Bounded contract

The `i64_array_bytes_output` entry point is
`prefix_sum_of_binomial_coefficient(input, length, output, capacity)`. Input is
`[T, N0, K0, ..., N(T-1), K(T-1)]`, with `1<=T<=16` and `0<=K<=N<=128` for
each query. The profile keeps the official fixed modulus 998244353 and caps
the official limits of `T,N<=200000`. Output is one unsigned 32-bit residue
per query in little-endian order, with no extra bytes. Success returns `4*T`;
malformed input returns `-1`; a null or undersized output returns `-2`. Errors
leave output unchanged.

The primary oracle uses the modular row ratio
`C(N,i+1)=C(N,i)*(N-i)/(i+1)` with a precomputed inverse table and accumulates
each prefix as it advances. Because every divisor is at most 128, it is
invertible modulo the fixed prime. The independent oracle sums Python's exact
`math.comb(N,i)` values and reduces only after the sum. This profile is distinct
from building each binomial coefficient with the local Pascal-addition DP.

[`workload.json`](workload.json) covers empty prefixes, partial and full rows,
multiple queries, maximum N, malformed frames, range errors, and output-buffer
errors. [`verify_workload.py`](verify_workload.py) checks fixture/oracle
agreement and the ten source paths without launching benchmark ports.

## Provenance and rights

The operation and official parameter limits come from Library Checker's
[Prefix Sum of Binomial Coefficient task](https://github.com/yosupo06/library-checker-problems/blob/master/enumerative_combinatorics/prefix_sum_of_binomial_coefficient/task.md)
and its [parameter file](https://github.com/yosupo06/library-checker-problems/blob/master/enumerative_combinatorics/prefix_sum_of_binomial_coefficient/info.toml).
The upstream repository is Apache-2.0; this project uses task metadata for
discovery and writes its implementations, fixtures, and oracles independently.
See [`RIGHTS.md`](RIGHTS.md).

## Implementations

| Language | Source |
|---|---|
| C | [`c/p/prefix_sum_of_binomial_coefficient.c`](../../../c/p/prefix_sum_of_binomial_coefficient.c) |
| C3 | [`c3/p/prefix_sum_of_binomial_coefficient.c3`](../../../c3/p/prefix_sum_of_binomial_coefficient.c3) |
| C++ | [`cpp/p/prefix_sum_of_binomial_coefficient.cpp`](../../../cpp/p/prefix_sum_of_binomial_coefficient.cpp) |
| Elisa | [`elisa/p/prefix_sum_of_binomial_coefficient.elisa`](../../../elisa/p/prefix_sum_of_binomial_coefficient.elisa) |
| Mojo | [`mojo/p/prefix_sum_of_binomial_coefficient.mojo`](../../../mojo/p/prefix_sum_of_binomial_coefficient.mojo) |
| Nim | [`nim/p/prefix_sum_of_binomial_coefficient.nim`](../../../nim/p/prefix_sum_of_binomial_coefficient.nim) |
| Odin | [`odin/p/prefix_sum_of_binomial_coefficient.odin`](../../../odin/p/prefix_sum_of_binomial_coefficient.odin) |
| Rust | [`rust/p/prefix_sum_of_binomial_coefficient.rs`](../../../rust/p/prefix_sum_of_binomial_coefficient.rs) |
| V | [`v/p/prefix_sum_of_binomial_coefficient.v`](../../../v/p/prefix_sum_of_binomial_coefficient.v) |
| Zig | [`zig/p/prefix_sum_of_binomial_coefficient.zig`](../../../zig/p/prefix_sum_of_binomial_coefficient.zig) |

Root owns shared byte-output suite imports, maps, bounds, and corpus wiring.
