# Coloured triangle reduction

Return the final colour produced by repeated adjacent-pair reduction in
`Z/3Z`.

## Contract

- Input is `[n, colors...]`, with `1 <= n <= 256`, exactly `n+1` signed
  64-bit values, and every color encoded as `0`, `1`, or `2`.
- Each round replaces every adjacent pair `(left, right)` with
  `-(left + right) mod 3`, producing one fewer color. The final result is in
  `{0,1,2}`. Malformed framing, count, or colors return `-1`.
- The primary uses the linear operator `R = -(I+S)`. For `r=n-1`, the final
  color is `(-1)^r * sum(C(r,k) * colors[k]) mod 3`. This is a row-wide sign
  alternating with the number of reduction rounds; the specified operation
  does not introduce an alternating sign by input index. Lucas' theorem
  computes each coefficient modulo 3 from base-three digits, without forming
  large binomial coefficients. The primary uses O(n log n) time and O(1)
  auxiliary space.
- The independent reference repeatedly builds each smaller row using the
  pair rule, taking O(n^2) time and O(n) space.

The operation is the algebraic encoding of the three-color rule used by the
[Codewars Coloured Triangles kata](https://www.codewars.com/kata/5a25ac6ac5e284cfbe000111);
that page served only as a discovery lead. This package defines its own numeric
contract and fixtures. The recurrence and Lucas coefficient method are
documented independently from the cited mathematical sources.

The `i64_array_scalar` runner and verifier dispatch, dual-reference workload
checks, and catalog entry are integrated in source. No executable checks have
been run. See [workload.json](workload.json), [RIGHTS.md](RIGHTS.md), and
[INVENTORY.md](INVENTORY.md).
