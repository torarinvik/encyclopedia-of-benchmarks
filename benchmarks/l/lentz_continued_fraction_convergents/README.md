# Lentz continued-fraction convergents

This package benchmarks Lentz's multiplicative convergent-ratio recurrence
for a finite generalized continued fraction. It computes the same mathematical
convergents as continuants when the pinned divisors are nonzero, but follows a
different state update from the repository's direct continuant and Steed
profiles.

## Contract

The `i64_array_bytes_output` frame is
`[N,b_0,a_1,b_1,...,a_N,b_N]`, with `1<=N<=8`, all values canonical in
`F_998244353`, and `b_0 != 0`. Exact input length is `2+2N`, so maximum valid
and parseable lengths are 18 and 19 words. Set `h_0=C_0=b_0` and `D_0=0`.
For each pair `(a_n,b_n)`, in this order, compute

```text
d_n = b_n + a_n D_(n-1)
c_n = b_n + a_n / C_(n-1)
D_n = 1 / d_n
Delta_n = D_n c_n
h_n = h_(n-1) Delta_n
```

All operations are in `F_998244353`. A zero `d_n`, a zero `C_(n-1)` needed
for division, or a zero `c_n` invalidates the full call with `-1`. We use a
strictly nonsingular subprofile and reject zero `c_n` even at the last stage;
the modified Lentz algorithm's tiny-value substitution is not meaningful over
a finite field. This preserves exact operations and makes error behavior
identical across ports. These finite traces do not claim convergence of an
infinite fraction.

Success emits `[N+1,h_0,...,h_N]` as little-endian signed-i64 words and returns
the byte count `8*(N+2)`, at most 80. Malformed input or a zero divisor returns
`-1`; null output or insufficient capacity returns `-2`, with no output writes
on errors. All singularity checks precede output-capacity handling. The native
ports keep a ten-word trace and scalar state within a 128-byte workspace cap.
The primary takes `O(N log p)` field operations due to modular inverses and
`O(N)` bounded output staging. The independent continuant reference takes
`O(N log p)` time and `O(N)` reference storage.

## References and distinction

The primary implements the `C_n`, `D_n`, and successive-convergent multiplier
recurrence described by Thompson and Barnett, Appendix III. The independent
reference constructs the numerator and denominator continuants directly and
divides each pair; it also pins the stricter nonsingular domain. NIST DLMF
[§3.10(iii)](https://dlmf.nist.gov/3.10.iii) lists Lentz's and modified
Lentz's methods as alternatives to Steed's algorithm. The local
[`continued_fraction_convergents`](../continued_fraction_convergents/README.md)
uses direct continuant recurrences; the
[`continued_fraction_forward_series_recurrence`](../continued_fraction_forward_series_recurrence/README.md)
uses a rho/term update; and
[`steed_continued_fraction_convergents`](../steed_continued_fraction_convergents/README.md)
uses additive `D_n` and `delta h_n` updates. Lentz's C/D ratios and
multiplicative `h_n` update are distinct benchmarked procedures.

Sources: [NIST DLMF §3.10(iii)](https://dlmf.nist.gov/3.10.iii), Lentz,
[“Generating Bessel Functions in Mie Scattering Calculations Using Continued
Fractions”](https://doi.org/10.1364/AO.15.000668), *Applied Optics* 15 (1976),
668–671, and Thompson–Barnett,
[“Coulomb and Bessel Functions of Complex Arguments and Order”](https://csclub.uwaterloo.ca/~pbarfuss/thompson1986.pdf),
*Journal of Computational Physics* 64 (1986), Appendix III. These sources are
used for algorithm descriptions only; see [RIGHTS.md](RIGHTS.md).

`workload.json` pins nonsingular traces, zero-divisor cases, maximum framing,
maximum output, and its one-byte-short capacity case. The primary and
independent references are package-local. The package is registered with the
shared `i64_array_bytes_output` runner and independent verifier, and appears
in the repository catalog.

| Language | Source |
|---|---|
| C | [lentz_continued_fraction_convergents.c](../../../c/l/lentz_continued_fraction_convergents.c) |
| C3 | [lentz_continued_fraction_convergents.c3](../../../c3/l/lentz_continued_fraction_convergents.c3) |
| C++ | [lentz_continued_fraction_convergents.cpp](../../../cpp/l/lentz_continued_fraction_convergents.cpp) |
| Elisa | [lentz_continued_fraction_convergents.elisa](../../../elisa/l/lentz_continued_fraction_convergents.elisa) |
| Mojo | [lentz_continued_fraction_convergents.mojo](../../../mojo/l/lentz_continued_fraction_convergents.mojo) |
| Nim | [lentz_continued_fraction_convergents.nim](../../../nim/l/lentz_continued_fraction_convergents.nim) |
| Odin | [lentz_continued_fraction_convergents.odin](../../../odin/l/lentz_continued_fraction_convergents.odin) |
| Rust | [lentz_continued_fraction_convergents.rs](../../../rust/l/lentz_continued_fraction_convergents.rs) |
| V | [lentz_continued_fraction_convergents.v](../../../v/lentz_continued_fraction_convergents.v) |
| Zig | [lentz_continued_fraction_convergents.zig](../../../zig/l/lentz_continued_fraction_convergents.zig) |
