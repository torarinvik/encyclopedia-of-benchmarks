# Sieve of Pritchard

This bounded profile returns the number of primes in `[2, N]` for one supplied
limit `2 <= N <= 1024`. The implementation follows Paul Pritchard's dynamic
wheel procedure: an ordered set begins as the first wheel, is extended by
rolling its current members through the next period, and has multiples of each
new wheel prime deleted in descending multiplier order. The ports represent
the ordered set with fixed array-backed forward and backward links. Prime 2 is
accounted for at initialization; each later selected wheel prime is counted
before it is removed from the candidate wheel.

The valid frame is `[N]` (one signed 64-bit word); only a one-word frame is
accepted. Null, empty, overlong, out-of-range, or malformed frames return
`-1`. The suite can frame at most two words to exercise the one trailing-word
case. The scalar result is `pi(N)`, the count of primes no greater than `N`.

The linked-wheel port uses two fixed arrays of 1,026 signed 32-bit indices.
Index `N+1` is a per-call sentinel, so total static table storage is 8,208
bytes. The package advertises a conservative 9,216-byte workspace cap,
including scalar locals and alignment. The primary has the wheel-sieve bound
of `O(N / log log N)` ordered-set operations and `O(N)` words of storage; the
independent trial-division oracle takes `O(N sqrt(N))` divisibility steps and
constant auxiliary space. Both are intentionally small bounded profiles.

The candidate was discovered from the RosettaCodeData popular-title index at
revision `1d475861d7141ef2fafff293d9339f56e4b0f5db`. The title was used only as
a discovery lead. The algorithm is specified from Pritchard's primary papers:
[A Sublinear Additive Sieve for Finding Prime Numbers (1981)](https://doi.org/10.1145/358527.358540)
and [Explaining the Wheel Sieve (1982)](https://doi.org/10.1007/BF00264164).

This is distinct from the repository's Eratosthenes-family, Sundaram, Atkin,
Euler/linear, and segmented sieve packages: those do not successively extend
and mutate an ordered candidate wheel with reverse deletion. The independent
oracle uses direct trial division and does not use a sieve.

## Languages

C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, and Zig.

The package is registered in the shared `i64_array_scalar` runner and verifier.
