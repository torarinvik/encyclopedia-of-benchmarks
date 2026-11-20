# Reservation: factorial last nonzero decimal digit

**Status:** Ten language ports, independent references, fixtures, documentation, static package checker, and scalar runner/verifier registration are present. Ports remain uncompiled and unexecuted by design.

## Contract

Use the `i64_array_scalar` ABI. The input is `[n]`, with `0 <= n <=
9223372036854775807`. Return the last nonzero decimal digit of `n!`; define
`0! = 1`. Invalid frames return `-1`.

The primary recurrence is `D(n) = D(floor(n/5)) * D(n mod 5) *
2^floor(n/5) mod 10`, with `D(0..4) = 1, 1, 2, 6, 4`. It takes
`O(log_5 n)` time and `O(log_5 n)` recursive space, or `O(1)` space when
iterated. An independent reference may use the base-five digit product
formula from Dresden's paper. The local factorial, trailing-zero, and
prime-factorial packages do not compute this decimal digit.

## Provenance and rights

The discovery lead was Codewars's title-only catalog; method context is the
independent [Dresden paper](https://dresden.academic.wlu.edu/files/2017/08/lnzd2.pdf)
and [OEIS A008904](https://oeis.org/A008904). Only the algorithmic idea and
formula are used. No problem text, code, examples, tests, or fixtures are
copied. Both references and the fixtures are independently written.
