# Stirling numbers of the second kind

## Contract

The official task asks for every S(N,k), for 0 <= k <= N, modulo
998244353, with 0 <= N <= 500000. The local profile accepts the signed
64-bit array [N] with 0 <= N <= 16. It computes the complete modular row,
then returns the scalar checksum

sum((k+1)^3 * S(N,k)) modulo 998244353.

The checksum adapts the full row to the existing i64_array_scalar ABI. It is
deterministic, but does not encode the row uniquely and is not a replacement
for the official row output. Invalid shapes or values return -1.

## Distinctness

The second-kind Stirling number S(N,k) counts partitions of an N-element
labeled set into exactly k nonempty blocks. The row contains these separate
counts for every k. The local bell_numbers package returns only the Bell
number B_N, the sum of the row; its Bell-triangle recurrence does not return
the coefficients. This profile keeps the row and combines all columns with
nonuniform weights before producing the ABI checksum.

The local partitions and integer_partition packages count integer partitions
of a number into positive summands. Their objects are unordered sums, not
partitions of a labeled set into k blocks. No local Stirling-number package
or matching contract was found.

The ports use S(n,k)=S(n-1,k-1)+k*S(n-1,k), with S(0,0)=1 and S(n,0)=0
for n>0. They update one row in descending k order, reducing each cell
modulo 998244353. The runtime is O(N^2), with O(N) workspace.

The recurrence oracle is in
[benchmarks/stirling_number_of_the_second_kind_oracle.py](../../stirling_number_of_the_second_kind_oracle.py).
The independent oracle uses the inclusion-exclusion formula
S(n,k)=1/k! * sum((-1)^(k-j) * C(k,j) * j^n, j=0..k), evaluated in the
same finite field.

Official task: [Library Checker — Stirling Number of the Second Kind](https://github.com/yosupo06/library-checker-problems/blob/master/enumerative_combinatorics/stirling_number_of_the_second_kind/task.md).
Official bounds: [info.toml](https://github.com/yosupo06/library-checker-problems/blob/master/enumerative_combinatorics/stirling_number_of_the_second_kind/info.toml).

## Workload and suite

workload.json records the checksum fixtures, invalid input cases, ABI, and
profile bounds. verify_workload.py statically compares both oracle results
with every fixture and checks all ten source paths. The workload is wired to
the i64_array_scalar runner and verifier. No program or checker was run while
creating this package.

## Language ports

| Language | Source |
|---|---|
| C | [c/s/stirling_number_of_the_second_kind.c](../../../c/s/stirling_number_of_the_second_kind.c) |
| C3 | [c3/s/stirling_number_of_the_second_kind.c3](../../../c3/s/stirling_number_of_the_second_kind.c3) |
| C++ | [cpp/s/stirling_number_of_the_second_kind.cpp](../../../cpp/s/stirling_number_of_the_second_kind.cpp) |
| Elisa | [elisa/s/stirling_number_of_the_second_kind.elisa](../../../elisa/s/stirling_number_of_the_second_kind.elisa) |
| Mojo | [mojo/s/stirling_number_of_the_second_kind.mojo](../../../mojo/s/stirling_number_of_the_second_kind.mojo) |
| Nim | [nim/s/stirling_number_of_the_second_kind.nim](../../../nim/s/stirling_number_of_the_second_kind.nim) |
| Odin | [odin/s/stirling_number_of_the_second_kind.odin](../../../odin/s/stirling_number_of_the_second_kind.odin) |
| Rust | [rust/s/stirling_number_of_the_second_kind.rs](../../../rust/s/stirling_number_of_the_second_kind.rs) |
| V | [v/s/stirling_number_of_the_second_kind.v](../../../v/s/stirling_number_of_the_second_kind.v) |
| Zig | [zig/s/stirling_number_of_the_second_kind.zig](../../../zig/s/stirling_number_of_the_second_kind.zig) |

## Rights

See [RIGHTS.md](RIGHTS.md) for source and rights details.
