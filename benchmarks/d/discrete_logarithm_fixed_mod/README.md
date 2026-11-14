# Batched discrete logarithms with a fixed modulus

This draft builds a shared table of powers of a primitive root, then answers a
batch of discrete-logarithm queries by direct lookup. It differs from
[`discrete_logarithm_mod`](../discrete_logarithm_mod/README.md), which solves
one general-modulus instance with extended baby-step giant-step and can handle
non-coprime bases. Here table construction is amortized across many targets.

The bounded `i64_array_bytes_output` contract is `[p,g,n,targets[n]]`.
`p` must be prime, `2 <= p <= 4093`; `g` must be a primitive root modulo `p`;
`1 <= n <= 256`; every target is in `[1,p-1]`. Emit the least nonnegative
exponent for each target as a little-endian signed 64-bit word. Invalid or null
input returns `-1`; null or short output returns `-2`; errors write nothing.
The maximum valid input is 259 words and output is at most 2048 bytes.

The intended primary performs trial-division primality validation, constructs
the complete power-to-exponent table while checking that the root generates
exactly `p-1` distinct nonzero residues, then looks up the batch. Its time is
O(p + n) after O(sqrt(p)) primality validation and storage is O(p). The
independent draft reference instead checks and searches each power sequence
directly; it intentionally does not share the lookup table.

The [Library Checker task](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/number_theory/discrete_logarithm_fixed_mod/task.md)
inspired the shared-modulus batch; its bounds are larger than this direct-table
profile. The source repository declares Apache-2.0. This contract and reference
are independently written from the algorithm idea.

Status: drafts in all ten supported languages, a direct reference, workload,
and suite registration are present. Nothing has been compiled or run.
