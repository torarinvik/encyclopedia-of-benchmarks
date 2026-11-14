# Logarithm of a set power series

This draft computes the formal logarithm in the square-zero algebra
`F_998244353[x0,...,x(n-1)]/(x0²,...,x(n-1)²)`. It is the inverse operation
of [`exp_of_set_power_series`](../../e/exp_of_set_power_series/README.md).
[`polynomial_composite_set_power_series`](../../p/polynomial_composite_set_power_series/README.md)
can express a truncated logarithm through supplied polynomial coefficients but
uses generic Horner composition; this specialized recurrence has different
state transitions and does not accept an arbitrary outer polynomial.

The `i64_array_bytes_output` input is `[n,coefficients[2^n]]`, with
`0 <= n <= 5`, coefficients in `[0,998244352]`, and constant coefficient 1.
Output is `2^n` little-endian i64 residues in mask order, with constant term
zero. Invalid or null input returns `-1`; null or short output returns `-2`
without writes. Maximum input length is 33 words and maximum output is 256
bytes.

For each nonempty mask choose its least significant bit as pivot. The
exponential set-partition identity expresses the input coefficient as the
sum over pivot-containing blocks of the logarithm coefficient times the
input coefficient on the remaining elements. Solving that identity in mask
order yields an O(3^n)-time, O(2^n)-space recurrence. The independent oracle
forms the truncated alternating series for `log(1+x)` using subset products.

The [Library Checker catalog item](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/set_power_series/log_of_set_power_series/task.md)
provides the operation idea; its repository declares Apache-2.0. The local
contract, code, and reference are independently authored without copying task
prose, source, or fixtures.

Status: all ten language drafts, an independent reference, a workload, and
byte-output suite registration are present. Verifier source specifies every
bounded dimension, maximum framing, invalid input, buffer boundaries, and
reference round trips through set-series exponential. Nothing has been compiled
or run.
