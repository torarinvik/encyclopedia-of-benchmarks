# Cornacchia descent for `x² + 2y² = p`

This benchmark finds the positive representation of an odd prime as
`p=x²+2y²` using Cornacchia's Euclidean remainder descent. The input supplies
the canonical root of `-2 mod p`, so this profile measures the descent and
square check without adding a modular-square-root algorithm.

## Contract

The ABI is `i64_array_scalar`; the exported symbol is `cornacchia_x2_plus_2y2`.
Input is `[p,r]`, where `3<=p<=1,000,000` is an odd prime and
`1<=r<=floor(p/2)` satisfies `r² ≡ -2 (mod p)`. There is one such canonical
root when a root exists. The exact frame length is 2 words and the parseable
length is 3. Null, malformed, composite/even/out-of-range `p`, or an invalid
root returns `-1`.

Cornacchia starts with `(previous,current)=(p,r)` and applies Euclidean
remainders until `current<=floor(sqrt(p))`. Set `x=current`, then test whether
`(p-x²)/2` is a positive exact square `y²`. A successful result packs the
positive pair as `1024*x+y`; decode with `x=result/1024` and `y=result%1024`.
For the bounded domain, `x<=999` and `y<=707`, so the packed scalar is
collision-free and at most `1,023,683`. Integer square roots use binary search
only. Trial division validates primality, and all products fit signed 64-bit.

The nearest local package, [`two_square_sum`](../../t/two_square_sum/README.md),
enumerates all ordered pairs for `n=x²+y²` by scanning coordinates. This
benchmark uses the different form `x²+2y²=p` and Cornacchia's root-seeded
Euclidean descent. It returns the unique positive pair for the prime form;
the independent oracle scans candidate x-coordinates directly.

## Provenance

The Euclidean-remainder version of Cornacchia's algorithm for
`x²+d y²=p` is described in Jesse Ira Deutsch, “Remarks on the Algorithms of
Cornacchia and Hermite-Serret,” *JP Journal of Algebra, Number Theory and
Applications* 53(2), 2022, [DOI](https://doi.org/10.17654/0972555522008), and
Alexander Munch-Hansen's thesis [*Quattro Formaggi*](https://cs.au.dk/fileadmin/ingen_mappe_valgt/phd_thesis/Alexander_Munch-Hansen.pdf),
§4.2.3. The implementation also follows the root-supplied interface described
by [FLINT's Cornacchia documentation](https://flintlib.org/doc/ecpp/ecpp_cornacchia.html).
Only the mathematical method is used; ports, references, fixtures, and docs
are clean-room work. See [`RIGHTS.md`](RIGHTS.md).

| Language | Source |
| --- | --- |
| C | [c/cornacchia_x2_plus_2y2.c](../../../c/c/cornacchia_x2_plus_2y2.c) |
| C3 | [c3/c/cornacchia_x2_plus_2y2.c3](../../../c3/c/cornacchia_x2_plus_2y2.c3) |
| C++ | [cpp/c/cornacchia_x2_plus_2y2.cpp](../../../cpp/c/cornacchia_x2_plus_2y2.cpp) |
| Elisa | [elisa/c/cornacchia_x2_plus_2y2.elisa](../../../elisa/c/cornacchia_x2_plus_2y2.elisa) |
| Mojo | [mojo/c/cornacchia_x2_plus_2y2.mojo](../../../mojo/c/cornacchia_x2_plus_2y2.mojo) |
| Nim | [nim/c/cornacchia_x2_plus_2y2.nim](../../../nim/c/cornacchia_x2_plus_2y2.nim) |
| Odin | [odin/c/cornacchia_x2_plus_2y2.odin](../../../odin/c/cornacchia_x2_plus_2y2.odin) |
| Rust | [rust/c/cornacchia_x2_plus_2y2.rs](../../../rust/c/cornacchia_x2_plus_2y2.rs) |
| V | [v/c/cornacchia_x2_plus_2y2.v](../../../v/c/cornacchia_x2_plus_2y2.v) |
| Zig | [zig/c/cornacchia_x2_plus_2y2.zig](../../../zig/c/cornacchia_x2_plus_2y2.zig) |

Fixtures cover the smallest prime, Euclidean descent, different pair shapes,
composite `p` with a valid root, wrong/noncanonical roots, a prime with no
root of `-2`, and malformed input. `verify_workload.py` describes a static
source and fixture inventory.
