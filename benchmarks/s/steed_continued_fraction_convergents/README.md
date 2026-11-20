# Steed continued-fraction convergents

This benchmark implements Steed's forward recurrence for a bounded
generalized continued fraction over `F_998244353`. It is distinct from
[`continued_fraction_convergents`](../continued_fraction_convergents/README.md),
which uses a simple-coefficient continuant recurrence, and from
[`continued_fraction_forward_series_recurrence`](../continued_fraction_forward_series_recurrence/README.md),
which is specialized to unit denominators and advances rho/term series state.

## Contract

The `i64_array_bytes_output` input is
`[N,b0,b1,a1,b2,a2,...,bN,aN]`, where `1<=N<=8` and every coefficient is a
canonical residue in `[0,998244352]`. The fraction prefixes are
`C0=b0` and `Cn=b0+a1/(b1+a2/(...+an/bn))`.

Steed's recurrence initializes `D1=1/b1`, `deltaC1=a1*D1`, and
`C1=C0+deltaC1`. For `n>=2`, it uses

```text
Dn       = 1 / (D_(n-1)*a_n + b_n)
deltaC_n = (b_n*Dn - 1) * deltaC_(n-1)
Cn       = C_(n-1) + deltaC_n
```

All operations are in the stated prime field. A zero `b1`, or a zero later
Steed divisor `D_(n-1)*a_n+b_n`, makes the full input invalid. Every required
divisor is checked before output-capacity validation. Malformed input or a
zero divisor returns `-1`; a null output or insufficient capacity returns
`-2` without writing. Success returns the byte count and emits
`[N+1,C0,C1,...,CN]` as little-endian signed-i64 words, with canonical
residues for each C.

Valid frames range from 4 to 18 words; a 19-word frame is parseable for
trailing-input rejection. The output ranges from 24 to 80 bytes. Native ports
use zero scratch beyond scalar recurrence state and the caller's output
buffer. Products of two field residues are below `p^2`, within signed-i64.

The primary uses Steed's D/deltaC/C recurrence twice: first to preflight every
divisor, then to write the outputs. The independent reference reduces each
finite fraction prefix from the right with homogeneous numerator/denominator
pairs and checks the resulting convergent denominator. It does not divide at
intermediate suffixes, so a zero intermediate pair component can still be
handled when the complete prefix is defined. Primary time is `O(N log p)`
modular operations due to Fermat inverses (`O(N)` for the fixed field); the
independent reference takes `O(N^2 + N log p)`. Both use `O(1)` native scratch.

## Provenance and rights

The recurrence follows NIST DLMF [§3.10(iii), Eq. 3.10.16](https://dlmf.nist.gov/3.10#E16)
and [Eq. 3.10.17](https://dlmf.nist.gov/3.10#E17).
This package's finite-field profile, error order, independent evaluator,
fixtures, and ports are written independently. No code, prose, examples, or
tests were copied; see [RIGHTS.md](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [steed_continued_fraction_convergents.c](../../../c/s/steed_continued_fraction_convergents.c) |
| C3 | [steed_continued_fraction_convergents.c3](../../../c3/s/steed_continued_fraction_convergents.c3) |
| C++ | [steed_continued_fraction_convergents.cpp](../../../cpp/s/steed_continued_fraction_convergents.cpp) |
| Elisa | [steed_continued_fraction_convergents.elisa](../../../elisa/s/steed_continued_fraction_convergents.elisa) |
| Mojo | [steed_continued_fraction_convergents.mojo](../../../mojo/s/steed_continued_fraction_convergents.mojo) |
| Nim | [steed_continued_fraction_convergents.nim](../../../nim/s/steed_continued_fraction_convergents.nim) |
| Odin | [steed_continued_fraction_convergents.odin](../../../odin/s/steed_continued_fraction_convergents.odin) |
| Rust | [steed_continued_fraction_convergents.rs](../../../rust/s/steed_continued_fraction_convergents.rs) |
| V | [steed_continued_fraction_convergents.v](../../../v/s/steed_continued_fraction_convergents.v) |
| Zig | [steed_continued_fraction_convergents.zig](../../../zig/s/steed_continued_fraction_convergents.zig) |

The package is registered in the shared `i64_array_bytes_output` runner and
independent verifier.
