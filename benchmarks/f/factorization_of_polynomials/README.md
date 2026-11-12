# Factorization of Polynomials

This package factors a monic polynomial over a small prime field into distinct
monic irreducibles and their multiplicities. It includes all ten benchmark
languages and is registered through the shared `i64_array_bytes_output`
interface.

## Bounded contract

Input words are `[N, p, a_0, ..., a_N]`, where `0<=N<=8`, `p` is one of
`2, 3, 5`, each coefficient is in `[0,p)`, and `a_N=1`. This includes the unit
polynomial (`N=0`, `a_0=1`), which has no factors. The bounded field and degree
keep an exhaustive algorithm practical across all languages; they are much
smaller than the official limits.

The output is a little-endian signed 64-bit word array:

```text
K
multiplicity_1 degree_1 b_1,0 ... b_1,degree_1
...
multiplicity_K degree_K b_K,0 ... b_K,degree_K
```

Factors are emitted in degree then coefficient-tuple order. A malformed call
returns `-1`; a valid call with a null output buffer or insufficient capacity
returns `-2` without writing. The maximum valid input is 11 words, maximum
parseable input is 12 words, maximum output is 27 words (216 bytes), and
workspace is bounded at 2,048 bytes.
The output bound is attained at degree eight over `F_5`, where six distinct
factors can fit; the smaller supported fields allow fewer distinct factors.

## Algorithm

The ports enumerate monic candidate polynomials of degrees through
`floor(N/2)`. Each candidate is tested for irreducibility by trial-dividing
through all monic polynomials up to half its degree. Irreducible candidates
are repeatedly divided out of the input, recording multiplicities. Any
remaining nonconstant polynomial is irreducible: if it were reducible, one of
its factors would have degree at most half its degree and would have appeared
in the exhaustive candidate set. For each candidate degree `d`, there are
`p^d` candidates and at most `sum(p^e, 1<=e<=floor(d/2))` trial divisors;
polynomial division costs `O(d^2)`. Extraction needs at most `N/d` divisions
per candidate, each `O(N*d)`. Overall this is
`O(sum_d p^d * (d^2 * sum_e p^e + N^2))`. At `p<=5` and `N<=8`, at most 780
candidates and 30 trial divisors per irreducibility check are considered;
the ports use fixed arrays.

The primary oracle uses the same irreducible-candidate sieve. The independent
oracle recursively splits a polynomial at any proper monic divisor, then
aggregates equal irreducible leaves; it does not use the candidate
irreducibility sieve.

## Provenance and rights

The task asks for monic irreducible factors and multiplicities over
`F_p`, including zero factors for `f=1`; its official limits are `N<=100` and
`p<=998244353`. This package uses a deliberately smaller profile. See the
official [task](https://github.com/yosupo06/library-checker-problems/blob/master/polynomial/factorization_of_polynomials/task.md),
[limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/polynomial/factorization_of_polynomials/info.toml),
and upstream [Apache-2.0 license](https://github.com/yosupo06/library-checker-problems/blob/master/LICENSE).
The package is clean-room; see [`RIGHTS.md`](RIGHTS.md).

[`workload.json`](workload.json) contains fixtures and ABI bounds.
[`verify_workload.py`](verify_workload.py) statically checks fixture/oracle
agreement, rights, and source inventory without launching ports. No program,
test, checker, build, compiler, or benchmark was run during preparation.

## Ports

| Language | Source |
|---|---|
| C | [`c/f/factorization_of_polynomials.c`](../../../c/factorization_of_polynomials.c) |
| C3 | [`c3/f/factorization_of_polynomials.c3`](../../../c3/factorization_of_polynomials.c3) |
| C++ | [`cpp/f/factorization_of_polynomials.cpp`](../../../cpp/f/factorization_of_polynomials.cpp) |
| Elisa | [`elisa/f/factorization_of_polynomials.elisa`](../../../elisa/f/factorization_of_polynomials.elisa) |
| Mojo | [`mojo/f/factorization_of_polynomials.mojo`](../../../mojo/f/factorization_of_polynomials.mojo) |
| Nim | [`nim/f/factorization_of_polynomials.nim`](../../../nim/f/factorization_of_polynomials.nim) |
| Odin | [`odin/f/factorization_of_polynomials.odin`](../../../odin/f/factorization_of_polynomials.odin) |
| Rust | [`rust/f/factorization_of_polynomials.rs`](../../../rust/f/factorization_of_polynomials.rs) |
| V | [`v/f/factorization_of_polynomials.v`](../../../v/f/factorization_of_polynomials.v) |
| Zig | [`zig/f/factorization_of_polynomials.zig`](../../../zig/f/factorization_of_polynomials.zig) |
