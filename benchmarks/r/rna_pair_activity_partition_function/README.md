# RNA pair-activity partition function

This bounded sum-product dynamic program totals the weights of all
noncrossing partial pairings over an ordered sequence of positions. It is a
context-independent integer-activity specialization of the RNA secondary
structure partition function.

## Contract

Input is `[n, w(0,1), w(0,2), ..., w(n-2,n-1)]`, with `0<=n<=16` and each
pair activity in `0..3`. Pair activities are supplied in row-major upper
triangle order: increasing left endpoint, then increasing right endpoint.
The valid length is exactly `1+n(n-1)/2`; the maximum is 121 words. One extra
parseable word is allowed so trailing data can be rejected. The empty sequence
is valid and has partition value 1.

Every set of selected pairs must be noncrossing and no position can occur in
more than one pair. A pair contributes its supplied activity, and a structure
has weight equal to the product of its pair activities. The result is the sum
of these weights over all structures; the empty structure contributes 1.
Activity zero disables a pair. Invalid framing, length, or activity returns
`-1`.

The primary interval DP anchors the right endpoint:

`Z[i,j] = Z[i,j-1] + sum(k=i..j-1, w(k,j) * Z[i,k-1] * Z[k+1,j-1])`.

An empty interval has value 1. The independent reference instead chooses
whether the leftmost position is unpaired or paired with a later position.
Both evaluate integer sums and products exactly. The recurrence takes O(n^3)
time and O(n^2) space. The native table has 16 by 16 signed-i64 entries, within
the 2,048-byte workspace cap. A conservative result bound is
`3^8 * T(16) = 303,162,394,896`, where `T(16)=46,206,736` is the number of
partial matchings on 16 labeled positions even when crossings are allowed;
this fits signed i64.

## Scope and provenance

This is distinct from [`rna_mfe_loop_energy_dp`](../rna_mfe_loop_energy_dp/README.md),
which minimizes a loop-energy objective, and from maximum-pair-count RNA
folding, which selects one structure under a different objective. This profile
does not take nucleotide identities, enforce canonical base pairs or minimum
hairpin lengths, model nearest-neighbor thermodynamics, calculate base-pair
probabilities, or permit pseudoknots.

The sum-product structure follows McCaskill's [partition-function dynamic
program](https://doi.org/10.1002/bip.360290621) and the *Encyclopedia of
Algorithms* [RNA Secondary Structure Boltzmann Distribution chapter 345](https://doi.org/10.1007/978-1-4939-2864-4_345).
The paper describes polynomial-order dynamic programming for the RNA
partition function; the `O(n^3)` bound also follows directly from the bounded
interval recurrence above. See [RIGHTS.md](RIGHTS.md) for reuse boundaries.

Ten language ports, a bounded workload, both reference recurrences, rights and
provenance, static inventory, and `i64_array_scalar` runner/verifier/catalog
registration are included. No programs, tests, helpers, builds, compilers,
profilers, or benchmarks were run.
