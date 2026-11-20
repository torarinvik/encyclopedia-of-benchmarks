# Shewchuk expansion summation

This benchmark sums an ordered sequence of exact dyadic values using floating-
point expansions. It exercises error-free `Two-Sum` transforms and the
`Grow-Expansion` procedure, preserving the low-order parts that ordinary
binary64 accumulation can discard. The result exposes the exact sum as an
integer count of `2^-30` units.

## Contract

The ABI is `i64_array_scalar`; the exported symbol is
`shewchuk_expansion_sum`. Input is `[n,(mantissa,exponent)*n]`, where `0<=n<=16`,
`|mantissa|<=2^24`, and `-30<=exponent<=0`. Each term means
`mantissa * 2^exponent`, exactly representable in IEEE-754 binary64. The frame
must contain exactly `1+2*n` signed-i64 values; valid and parseable lengths are
at most 33 and 34. Null and malformed inputs return `-1`.

The output is the exact dyadic sum multiplied by `2^30`, plus `2^58+1`. Every
legal input is therefore an integer number of output units, and this positive
offset keeps valid results distinct from the `-1` invalid sentinel. Since
there are at most 16 terms, valid results range from 1 through `2^59+1` within
signed i64. An empty sequence returns `2^58+1`.

The primary starts with an empty, low-to-high nonoverlapping expansion. For
each nonzero term it applies `Grow-Expansion`: pass a running high component
through the expansion with general `Two-Sum`, retaining each exact residual,
then append the final high component. It converts each component to exact
`2^-30` units, sums those integers, and adds the output offset. IEEE binary64 round-to-nearest,
ties-to-even is assumed, and floating reassociation or fast-math is excluded.
The independent oracle does no floating-point work: it shifts each mantissa
directly into integer `2^-30` units and sums them.

The numerical method is distinct from [`kahan_summation`](../../k/kahan_summation/README.md).
Kahan maintains one correction value and returns a rounded binary64 result;
this profile maintains a multi-component expansion and returns the exact
bounded dyadic sum. For example, the sequence `2^24, 2^-30, -2^24` has exact
result one output unit, while ordinary ordered addition loses the middle term.

## Provenance

The method follows Jonathan Richard Shewchuk's [1997 paper on adaptive
precision floating-point arithmetic](https://doi.org/10.1007/PL00009321),
especially its `Two-Sum` and `Grow-Expansion` algorithms. An [author-hosted
paper copy](https://people.eecs.berkeley.edu/~jrs/papers/robustr.pdf) is
available. The ports use the algorithmic ideas only; no paper source code or
prose is copied. See [`RIGHTS.md`](RIGHTS.md).

| Language | Source |
| --- | --- |
| C | [c/s/shewchuk_expansion_sum.c](../../../c/s/shewchuk_expansion_sum.c) |
| C3 | [c3/s/shewchuk_expansion_sum.c3](../../../c3/s/shewchuk_expansion_sum.c3) |
| C++ | [cpp/s/shewchuk_expansion_sum.cpp](../../../cpp/s/shewchuk_expansion_sum.cpp) |
| Elisa | [elisa/s/shewchuk_expansion_sum.elisa](../../../elisa/s/shewchuk_expansion_sum.elisa) |
| Mojo | [mojo/s/shewchuk_expansion_sum.mojo](../../../mojo/s/shewchuk_expansion_sum.mojo) |
| Nim | [nim/s/shewchuk_expansion_sum.nim](../../../nim/s/shewchuk_expansion_sum.nim) |
| Odin | [odin/s/shewchuk_expansion_sum.odin](../../../odin/s/shewchuk_expansion_sum.odin) |
| Rust | [rust/s/shewchuk_expansion_sum.rs](../../../rust/s/shewchuk_expansion_sum.rs) |
| V | [v/s/shewchuk_expansion_sum.v](../../../v/s/shewchuk_expansion_sum.v) |
| Zig | [zig/s/shewchuk_expansion_sum.zig](../../../zig/s/shewchuk_expansion_sum.zig) |

[`workload.json`](workload.json) includes cancellation recovery, overlapping
exponents, signed small values, the maximum valid frame, a trailing-word frame,
and malformed/null inputs. `primary_oracle.py` implements Grow-Expansion;
`independent_oracle.py` uses exact integer units. `verify_workload.py` checks
the package inventory and fixture metadata without executing the benchmark.
