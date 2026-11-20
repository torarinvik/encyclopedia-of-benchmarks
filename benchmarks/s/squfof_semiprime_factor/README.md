# Bounded SQUFOF factor search

This package profiles Shanks's square form factorization (SQUFOF) through its continued-fraction form: an online forward walk over reduced quadratic forms, tests for square remainders at even indices, and a reverse walk from each square to a symmetry point. It returns the smaller member of the first proper factor pair found. A prime or a bounded run with no proper factor returns `0`.

## Contract

The `i64_array_scalar` input is `[N, forward_cap, reverse_cap]`.

- `N` is an odd signed integer in `3..1,000,000,000,000`. Perfect squares are accepted and return their integer square root immediately.
- Each cap is in `0..256`. `forward_cap` counts forward continued-fraction transitions from `(P₁,Q₁)`; only states at even continued-fraction indices are tested. `reverse_cap` counts transitions for each inverse-square-root walk.
- The fixed multiplier is one. Set `D=N` when `N ≡ 3 (mod 4)` and `D=2N` when `N ≡ 1 (mod 4)`. This is the normalization in Gower–Wagstaff §3.1–3.3 for odd inputs.
- On a square-form hit, initialize the reverse state from its integer square root. If the reverse walk reaches equal consecutive numerators, compute `g=gcd(N,R)`. A proper `g` returns `min(g,N/g)`; a trivial gcd, a reverse-cap exhaustion, or a forward-cap exhaustion continues the forward scan or returns `0` when no steps remain.
- Malformed framing, even or out-of-range `N`, or a cap outside its range returns `-1`. Valid and parseable input lengths are 3 and 4 signed 64-bit words.

The forward recurrence is `b=floor((a+P)/Q)`, `Pnext=bQ-P`, `Qnext=Qprevious+b(P-Pnext)`. The ports use this streaming update. The primary oracle follows the same recurrence. The independent reference stores bounded complete-quotient states using the classical `(m,d,a_n)` recurrence and reconstructs each next denominator from `dnext=(D-mnext²)/d`; its reverse phase uses the invariant `Snext=(D-Rnext²)/S`. Both references preserve the caps, even-index test, proper-gcd rule, and bounded-miss result.

All arithmetic stays within signed 64-bit range under the `N` bound: `D≤2·10^12`, `a≤1,414,213`, and the reduced `P,Q,R,S` states are below `2√D`; recurrence products are bounded by the discriminant-scale state relation. The native ports use no heap scratch; the registered 512-byte workspace allowance covers their fixed scalar state and call frames. The independent oracle's bounded Python state list is reference-only and is not charged to the native workspace.

## References and duplicate boundary

The algorithm description follows Daniel Shanks's [manuscript](https://homes.cerias.purdue.edu/~ssw/shanks.pdf) and the detailed continued-fraction algorithm in Gower and Wagstaff's [analysis](https://homes.cerias.purdue.edu/~ssw/squfof.pdf), especially §3.1–3.3. The score-19 RosettaCodeData [pinned title index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks) was used only to discover this candidate; no task wording, code, examples, or fixtures were copied.

This is distinct from local factorization profiles: Fermat factorization scans successive `a²−N` square differences; Pollard rho searches a polynomial cycle; Pollard p−1 raises a base using smooth prime powers; trial division tests candidate divisors. SQUFOF instead detects square remainders in the continued fraction of `√D` and uses an inverse square-root/reverse-form walk. The implementation omits Shanks's small-residue queue prefilter: every even-index square is tried, and a trivial gcd simply resumes the bounded forward walk.

## Language ports

| Language | Source |
|---|---|
| C | [`squfof_semiprime_factor.c`](../../../c/s/squfof_semiprime_factor.c) |
| C3 | [`squfof_semiprime_factor.c3`](../../../c3/s/squfof_semiprime_factor.c3) |
| C++ | [`squfof_semiprime_factor.cpp`](../../../cpp/s/squfof_semiprime_factor.cpp) |
| Elisa | [`squfof_semiprime_factor.elisa`](../../../elisa/s/squfof_semiprime_factor.elisa) |
| Mojo | [`squfof_semiprime_factor.mojo`](../../../mojo/s/squfof_semiprime_factor.mojo) |
| Nim | [`squfof_semiprime_factor.nim`](../../../nim/s/squfof_semiprime_factor.nim) |
| Odin | [`squfof_semiprime_factor.odin`](../../../odin/s/squfof_semiprime_factor.odin) |
| Rust | [`squfof_semiprime_factor.rs`](../../../rust/s/squfof_semiprime_factor.rs) |
| V | [`squfof_semiprime_factor.v`](../../../v/s/squfof_semiprime_factor.v) |
| Zig | [`squfof_semiprime_factor.zig`](../../../zig/s/squfof_semiprime_factor.zig) |

The package includes a primary oracle, an independent complete-quotient reference, bounded workload fixtures, rights/provenance notes, static inventory helpers, and `i64_array_scalar` runner/verifier/catalog registration. All work is source-only; no programs, tests, helpers, builds, compilers, profilers, or benchmarks were run.
