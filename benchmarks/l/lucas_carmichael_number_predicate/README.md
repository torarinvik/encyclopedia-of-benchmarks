# Lucas–Carmichael number predicate

Classify a positive integer using the Lucas–Carmichael divisibility condition.
This benchmark measures a bounded factor walk and squarefreeness check together
with the prime-factor successor-divisibility predicate.

## Contract

- ABI: `i64_array_scalar`; symbol: `lucas_carmichael_number_predicate`.
- Input is exactly `[n]`, with `1 <= n <= 1,000,000`. Null input, wrong length,
  or an out-of-range value returns `-1`.
- Return `1` exactly when `n` is composite and squarefree and every prime divisor
  `p` of `n` satisfies `(p + 1) | (n + 1)`. Return `0` otherwise. Thus 1 and
  primes return 0.
- The factor walk removes each discovered prime power. An exponent above one
  rejects the candidate as non-squarefree. A final residual greater than one is
  treated as the last prime factor after all smaller trial divisors were checked.

This criterion differs from the ordinary Carmichael criterion `p - 1 | n - 1`.
The local `carmichael_number`, Carmichael lambda, Chernick multiplier, and
three-prime Carmichael packages perform different operations; none classifies
Lucas–Carmichael numbers by the `p + 1` condition.

## Bounded algorithms and references

The primary implementation tries integer divisors against the shrinking
residual. At `n <= 1,000,000`, it tests no candidate greater than 1,000, so the
walk takes at most 999 candidates. It rejects repeated factors and checks the
divisibility condition as it visits each distinct prime.

The independent reference sieves the primes through 1,000, checks divisibility
against the original input, detects repeated factors with `p²`, and tests the
remaining cofactor separately. The methods do not share the primary's residual
factor walk. Native values and `n+1` are bounded well inside signed 64-bit range;
the native workspace allowance is 128 bytes and excludes caller-owned input.

The criterion and sequence are listed by [OEIS A006972](https://oeis.org/A006972)
and defined by [MathWorld](https://mathworld.wolfram.com/Lucas-CarmichaelNumber.html).
The pinned [RosettaCodeData popular-title index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks)
is used only to discover the task title. See [RIGHTS.md](RIGHTS.md).

The [hand-pinned workload](workload.json) includes known sequence members,
ordinary Carmichael and squareful composites, the profile maximum, malformed
framing, and null input. It is registered with the `i64_array_scalar`
runner and verifier.

## Language ports

| Language | Source |
|---|---|
| C | [c/l/lucas_carmichael_number_predicate.c](../../../c/l/lucas_carmichael_number_predicate.c) |
| C3 | [c3/l/lucas_carmichael_number_predicate.c3](../../../c3/l/lucas_carmichael_number_predicate.c3) |
| C++ | [cpp/l/lucas_carmichael_number_predicate.cpp](../../../cpp/l/lucas_carmichael_number_predicate.cpp) |
| Elisa | [elisa/l/lucas_carmichael_number_predicate.elisa](../../../elisa/l/lucas_carmichael_number_predicate.elisa) |
| Mojo | [mojo/l/lucas_carmichael_number_predicate.mojo](../../../mojo/l/lucas_carmichael_number_predicate.mojo) |
| Nim | [nim/l/lucas_carmichael_number_predicate.nim](../../../nim/l/lucas_carmichael_number_predicate.nim) |
| Odin | [odin/l/lucas_carmichael_number_predicate.odin](../../../odin/l/lucas_carmichael_number_predicate.odin) |
| Rust | [rust/l/lucas_carmichael_number_predicate.rs](../../../rust/l/lucas_carmichael_number_predicate.rs) |
| V | [v/l/lucas_carmichael_number_predicate.v](../../../v/l/lucas_carmichael_number_predicate.v) |
| Zig | [zig/l/lucas_carmichael_number_predicate.zig](../../../zig/l/lucas_carmichael_number_predicate.zig) |

The references, workload helper, and inventory helper were authored for static
review. No port, program, test, or helper has been run.
