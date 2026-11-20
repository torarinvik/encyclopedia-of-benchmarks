# Source and rights

- Algorithm source: OI Wiki, “Powerful Number sieve,” which derives the
  powerful-number support and the summatory convolution identity:
  [oi-wiki.org/math/number-theory/powerful-number](https://oi-wiki.org/math/number-theory/powerful-number/).
- An independent contest exposition gives the `f(p^e)=p^(e-1)` example and
  derives `(mu*f)(p^e)=p^(e-1)-p^(e-2)` for `e>=2`:
  [AtCoder ABC370 editorial, Problem G](https://atcoder.jp/contests/abc370/editorial/10882).
- This benchmark reimplements the powerful-number enumeration and convolution
  idea with an independent direct-factorization oracle. Its interface, bounded
  profile, fixtures, and ports are original clean-room work; no source code is
  redistributed.
