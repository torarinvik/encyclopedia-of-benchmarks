# Powerful-number summatory sieve

This bounded profile computes
`F(N)=sum(n/rad(n), n=1..N)`, where `rad(n)` is the product of the distinct
prime factors of `n`. The summand is multiplicative, with `f(p^e)=p^(e-1)`.

## Algorithm

Write `f = 1 * h`, where `1(n)=1` is the constant-one multiplicative
function and `h=mu*f`. At prime powers, `h(p)=0` and
`h(p^e)=p^(e-1)-p^(e-2)=(p-1)p^(e-2)` for `e>=2`. Therefore `h(d)` is
nonzero only when every prime dividing `d` has exponent at least two: exactly
the powerful numbers. Since the prefix sum of `1` is `G(x)=x`,

`F(N) = sum(h(d) * floor(N/d), d powerful, d<=N)`.

The reference sieves primes through `sqrt(N)`, recursively selects increasing
primes and exponents at least two, and adds each powerful-number term once.
The independent oracle instead factors every integer through a smallest-prime
factor table and sums `n/rad(n)` directly.

## Contract

- `i64_array_scalar` input is `[N]`, with `1 <= N <= 1,000,000`.
- Return the exact prefix sum; invalid input returns `-1`.
- The result is at most `N(N+1)/2`, so the full profile fits signed 64-bit.
- The bounded reference uses a prime sieve through `sqrt(N)` and visits each
  powerful number once. The number of powerful numbers through N is O(sqrt N);
  prime-sieve storage is O(sqrt N).

## Distinction from local summatory functions

The local Min_25 profile handles a different prime-power family with quotient
blocks. This benchmark makes the convolution support sparse by using
`h=mu*f`, then enumerates only powerful numbers. The local square-free count
and Möbius-function packages also do not compute this summatory function.

## References

- [OI Wiki: Powerful Number sieve](https://oi-wiki.org/math/number-theory/powerful-number/)
- [AtCoder ABC370 editorial: Powerful Number sieve](https://atcoder.jp/contests/abc370/editorial/10882)
