# Dedekind sum by Euclidean reciprocity

This benchmark computes the classical Dedekind sum using its reciprocity law.
The primary reduces the input pair through Euclidean remainders and evaluates
an exact integer recurrence. The independent reference evaluates the defining
finite sawtooth sum directly.

## Contract

The ABI is `i64_array_scalar`; the exported symbol is
`dedekind_sum_reciprocity`. Input is `[h,k]`, where `1<=k<=100,000`,
`0<=h<k`, and `gcd(h,k)=1`. The exact frame length is two words and the
parseable length is three. Null, malformed, noncanonical, out-of-range, or
non-coprime inputs return `-1`. The unit case `[0,1]` is valid and has sum 0.

For the sawtooth function `((x))={x}-1/2` when `x` is not an integer and zero
otherwise, the classical sum is
`s(h,k)=sum_{j=1}^{k-1} ((j/k))*((h*j/k))`. The benchmark computes the integer
`S=12*k*s(h,k)`. Dedekind reciprocity gives the scaled Euclidean recurrence
`S(h,k)=(h²+k²+1-3hk-k*S(k mod h,h))/h` for `0<h<k`, with `S(0,1)=0`.
The primary applies this recurrence in O(log k) Euclidean steps. The direct
oracle uses the finite sum in O(k) time.

The returned scalar is `S+29,999,700,001`; subtract that offset to recover
`S`, then divide by `12*k` to recover the rational sum. Every sawtooth value
has magnitude at most 1/2, so `|S|<=3*k*(k-1)<=29,999,700,000`. The offset
keeps every valid result positive and separate from the invalid sentinel; the
result bound is `59,999,400,001`. Intermediate products also fit signed
64-bit integers at the modulus limit.

This profile is distinct from [`jacobi_symbol`](../../j/jacobi_symbol/README.md):
that benchmark returns a quadratic-residue symbol through quadratic
reciprocity, while this one evaluates a rational sawtooth sum through
Dedekind reciprocity. It is also distinct from `bernoulli_number`, which
computes Bernoulli values rather than a Dedekind sum.

## Provenance

The definition and reciprocity law are formalized in the [Archive of Formal
Proofs entry on Dedekind sums](https://isa-afp.org/entries/Dedekind_Sums.html),
which follows Apostol, *Modular Functions and Dirichlet Series in Number
Theory*, Chapter 3. The algorithm is derived from the classical identity;
all ports, references, fixtures, and prose here are clean-room work. See
[`RIGHTS.md`](RIGHTS.md).

| Language | Source |
| --- | --- |
| C | [c/d/dedekind_sum_reciprocity.c](../../../c/d/dedekind_sum_reciprocity.c) |
| C3 | [c3/d/dedekind_sum_reciprocity.c3](../../../c3/d/dedekind_sum_reciprocity.c3) |
| C++ | [cpp/d/dedekind_sum_reciprocity.cpp](../../../cpp/d/dedekind_sum_reciprocity.cpp) |
| Elisa | [elisa/d/dedekind_sum_reciprocity.elisa](../../../elisa/d/dedekind_sum_reciprocity.elisa) |
| Mojo | [mojo/d/dedekind_sum_reciprocity.mojo](../../../mojo/d/dedekind_sum_reciprocity.mojo) |
| Nim | [nim/d/dedekind_sum_reciprocity.nim](../../../nim/d/dedekind_sum_reciprocity.nim) |
| Odin | [odin/d/dedekind_sum_reciprocity.odin](../../../odin/d/dedekind_sum_reciprocity.odin) |
| Rust | [rust/d/dedekind_sum_reciprocity.rs](../../../rust/d/dedekind_sum_reciprocity.rs) |
| V | [v/d/dedekind_sum_reciprocity.v](../../../v/d/dedekind_sum_reciprocity.v) |
| Zig | [zig/d/dedekind_sum_reciprocity.zig](../../../zig/d/dedekind_sum_reciprocity.zig) |

Fixtures include the unit modulus, zero and nonzero values, both signs, a
several-step descent, maximum positive and negative sums, non-coprime inputs,
boundaries, and malformed frames. `verify_workload.py` provides a static
package inventory; it is not run here.
