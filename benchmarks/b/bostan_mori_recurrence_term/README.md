# Bostan–Mori recurrence term

Compute a distant term of a homogeneous linear recurrence over the prime field
F_998244353. The benchmark isolates the Bostan–Mori method, which repeatedly
halves the requested index by extracting even or odd coefficients from
polynomial products.

## Contract

The exported scalar ABI symbol is `bostan_mori_recurrence_term`. Input is
`[d,k,c1,...,cd,a0,...,a(d-1)]`, where `1<=d<=8`,
`0<=k<=10^18`, and each coefficient and initial term is in
`[0,998244352]`. The recurrence is
`a_n = c1*a_(n-1) + ... + cd*a_(n-d) (mod 998244353)` for `n>=d`.
The output is `a_k` modulo 998244353. Wrong lengths or out-of-range fields
return `-1`. The largest valid frame has 18 signed 64-bit words; the parse
cap is 19 to represent one trailing-word error.

## Algorithms

The primary ports form `Q(x)=1-c1*x-...-cd*x^d` and the numerator `P(x)` of
the recurrence generating function `P(x)/Q(x)`. At each iteration they
multiply by `Q(-x)`. Since `Q(x)Q(-x)` contains only even powers, selecting
the numerator coefficients matching the current index parity and the
denominator's even coefficients gives a new rational series for index
`floor(k/2)`. Direct convolution is used because the order is bounded by eight.
The method uses `O(d^2 log(k+1))` time and `O(d)` working space.

The independent oracle raises the recurrence companion matrix by binary
exponentiation, using `O(d^3 log(k+1))` time and `O(d^2)` space. This differs
from the Bostan–Mori numerator/denominator reduction.

## Distinctness and provenance

[`linear_recurrence_matrix`](../../l/linear_recurrence_matrix/README.md)
computes recurrence values by matrix exponentiation under a different source
contract and modulus. [`berlekamp_massey`](../../b/berlekamp_massey/README.md)
infers recurrence coefficients from observed values. Neither implements the
Bostan–Mori coefficient-halving procedure.

The algorithm is based on Bostan and Mori, [“A Simple and Fast Algorithm for
Computing the N-th Term of a Linearly Recurrent Sequence”](https://arxiv.org/abs/2008.08822).
Only the algorithm idea is used; the workload, ABI, oracles, and ten ports are
independent clean-room work. No code or paper prose was copied.

See [`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json), the [primary
oracle](../../bostan_mori_recurrence_term_oracle.py), the [matrix oracle](../../bostan_mori_recurrence_term_verifier_oracle.py),
and the [static inventory checker](../../check_bostan_mori_recurrence_term_package.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/bostan_mori_recurrence_term.c`](../../../c/b/bostan_mori_recurrence_term.c) |
| C3 | [`c3/bostan_mori_recurrence_term.c3`](../../../c3/b/bostan_mori_recurrence_term.c3) |
| C++ | [`cpp/bostan_mori_recurrence_term.cpp`](../../../cpp/b/bostan_mori_recurrence_term.cpp) |
| Elisa | [`elisa/bostan_mori_recurrence_term.elisa`](../../../elisa/b/bostan_mori_recurrence_term.elisa) |
| Mojo | [`mojo/bostan_mori_recurrence_term.mojo`](../../../mojo/b/bostan_mori_recurrence_term.mojo) |
| Nim | [`nim/bostan_mori_recurrence_term.nim`](../../../nim/b/bostan_mori_recurrence_term.nim) |
| Odin | [`odin/bostan_mori_recurrence_term.odin`](../../../odin/b/bostan_mori_recurrence_term.odin) |
| Rust | [`rust/bostan_mori_recurrence_term.rs`](../../../rust/b/bostan_mori_recurrence_term.rs) |
| V | [`v/bostan_mori_recurrence_term.v`](../../../v/b/bostan_mori_recurrence_term.v) |
| Zig | [`zig/bostan_mori_recurrence_term.zig`](../../../zig/b/bostan_mori_recurrence_term.zig) |
