# Binomial coefficient modulo a prime power

Compute ordinary binomial coefficients modulo a prime power, including cases
where the denominator of the factorial quotient is not invertible modulo the
chosen modulus.

## Distinction from local packages

[`ncr_modulo_p`](../ncr_modulo_p/README.md) builds a factorial table and tries
to invert its denominator. With a composite modulus, that denominator may not
have an inverse, and the source-specific contract returns `-1`. Exact
[`binomial_coefficient`](../binomial_coefficient/README.md) and Pascal-row
packages do not perform p-adic cancellation. This package strips all factors of
the prime from factorials, tracks their exponent separately, and inverts only
the remaining units.

## Bounded contract

The C ABI symbol is `binomial_coefficient_prime_power(input, length, output,
capacity)` under the `i64_array_bytes_output` family. The input is
`[p,e,Q,(n,k)*Q]`:

- `p` is prime and `2<=p<=31`.
- `1<=e<=8` and the modulus `p^e` is at most `1,000,000,000`.
- `0<=Q<=32`, with `0<=k<=n<=128` for each query.
- Input has exactly `3+2*Q` signed 64-bit words; the maximum valid length is
  67 and maximum parseable length is 68.
- Output is one little-endian unsigned 32-bit residue modulo `p^e` per query.
  It contains no terminator; the scalar result is the output byte count, up to
  128 bytes.
- Invalid input returns `-1`; invalid capacity or a null/short output buffer
  for `Q>0` returns `-2`. Errors leave output untouched.
- A valid zero-query frame `[p,e,0]` returns 0 and accepts a null output
  pointer. Input validation takes precedence over output-buffer checks.
- Workspace is declared as 2560 bytes: two fixed 129-entry i64 tables, compact
  u16 p-adic valuations, and staged u32 residues fit within the reservation.

The primary uses the recurrence `c(n)=floor(n/p)+c(floor(n/p))` for the
valuation of `n!`, and builds the p-free factorial part by combining the
prefix product of integers not divisible by `p` with the value at
`floor(n/p)`. For each coefficient, it checks the valuation difference,
returns zero when that difference reaches `e`, and otherwise multiplies by the
prime power and modular inverses of the two p-free denominator parts. Euler's
theorem computes inverses modulo `p^e` because these parts are units.

The independent oracle builds each queried Pascal row by descending additions
modulo `p^e`; it uses no modular division. Both oracles accept tuple and list
inputs. The workload includes prime-power divisibility, unit denominators,
zero queries, the maximum input/output frame, malformed records, null output,
and capacity failures. The package-local static inventory checker compares
fixtures against both oracles and confirms all ten source paths without
launching any port.

## Provenance

The mathematical method comes from CP-Algorithms, [Binomial Coefficients —
binomial coefficient modulo prime power](https://cp-algorithms.com/combinatorics/binomial-coefficients.html#binomial-coefficient-modulo-prime-power),
licensed CC BY-SA 4.0. Implementations and workload data are clean-room; see
[`RIGHTS.md`](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/b/binomial_coefficient_prime_power.c`](../../../c/b/binomial_coefficient_prime_power.c) |
| C3 | [`c3/b/binomial_coefficient_prime_power.c3`](../../../c3/b/binomial_coefficient_prime_power.c3) |
| C++ | [`cpp/b/binomial_coefficient_prime_power.cpp`](../../../cpp/b/binomial_coefficient_prime_power.cpp) |
| Elisa | [`elisa/b/binomial_coefficient_prime_power.elisa`](../../../elisa/b/binomial_coefficient_prime_power.elisa) |
| Mojo | [`mojo/b/binomial_coefficient_prime_power.mojo`](../../../mojo/b/binomial_coefficient_prime_power.mojo) |
| Nim | [`nim/b/binomial_coefficient_prime_power.nim`](../../../nim/b/binomial_coefficient_prime_power.nim) |
| Odin | [`odin/b/binomial_coefficient_prime_power.odin`](../../../odin/b/binomial_coefficient_prime_power.odin) |
| Rust | [`rust/b/binomial_coefficient_prime_power.rs`](../../../rust/b/binomial_coefficient_prime_power.rs) |
| V | [`v/b/binomial_coefficient_prime_power.v`](../../../v/b/binomial_coefficient_prime_power.v) |
| Zig | [`zig/b/binomial_coefficient_prime_power.zig`](../../../zig/b/binomial_coefficient_prime_power.zig) |
