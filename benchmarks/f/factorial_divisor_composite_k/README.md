# Composite divisor power in a factorial

Given `n` and a composite integer `k`, return the largest exponent `x` such
that `k^x` divides `n!`.

## Contract

- The binary scalar ABI receives unsigned 64-bit values `[n, k]`.
- `0 <= n <= 1,000,000,000,000` and `4 <= k <= 1,000,000`.
- `k` must be composite. Prime `k` is excluded because the local
  [`largest_power`](../../l/largest_power/README.md) profile directly returns
  the corresponding prime valuation; `k=5` is also the core operation in
  [`factorial_trailing_zeroes`](../../f/factorial_trailing_zeroes/README.md).
- Invalid or out-of-profile input returns `-1`.
- The exported C ABI symbol is `int64_t factorial_divisor_composite_k(uint64_t n, uint64_t k)`.
- For valid input, factor `k = product(p_i ^ e_i)`, compute
  `v_p(n!) = floor(n/p) + floor(n/p^2) + ...` for every distinct prime factor,
  then return `min(floor(v_p(n!)/e_i))`.
- The trial factorization costs `O(sqrt(k))`; the valuation work is
  `O(sum(log_p(n+1)))`. Auxiliary storage is constant.

This composite-only contract adds the factorization and cross-prime minimum
needed for arbitrary composite divisors. It does not add another prime-only
Legendre-valuation benchmark.

## Workload and references

[`workload.json`](workload.json) covers prime-power and multi-prime composite
divisors, `n=0`, small and large factorials, both numeric bounds, prime-k
rejection, and malformed ranges. The primary reference factors `k` by
successive trial division and evaluates each Legendre sum by repeated integer
division. The independent reference searches prime divisors separately and
uses the base-`p` digit-sum identity for each valuation. The package-local
[`check_inventory.py`](check_inventory.py) statically checks the ten source
files, workload metadata, and fixture agreement with both references.

The method follows CP-Algorithms, [Finding Power of Factorial Divisor —
Composite `k`](https://cp-algorithms.com/algebra/factorial-divisors.html#composite-k).
Only the mathematical algorithm idea was used; implementations, references,
contracts, fixtures, and prose here are independently authored.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/factorial_divisor_composite_k.c`](../../../c/f/factorial_divisor_composite_k.c) |
| C3 | [`c3/f/factorial_divisor_composite_k.c3`](../../../c3/f/factorial_divisor_composite_k.c3) |
| C++ | [`cpp/f/factorial_divisor_composite_k.cpp`](../../../cpp/f/factorial_divisor_composite_k.cpp) |
| Elisa | [`elisa/f/factorial_divisor_composite_k.elisa`](../../../elisa/f/factorial_divisor_composite_k.elisa) |
| Mojo | [`mojo/f/factorial_divisor_composite_k.mojo`](../../../mojo/f/factorial_divisor_composite_k.mojo) |
| Nim | [`nim/f/factorial_divisor_composite_k.nim`](../../../nim/f/factorial_divisor_composite_k.nim) |
| Odin | [`odin/f/factorial_divisor_composite_k.odin`](../../../odin/f/factorial_divisor_composite_k.odin) |
| Rust | [`rust/f/factorial_divisor_composite_k.rs`](../../../rust/f/factorial_divisor_composite_k.rs) |
| V | [`v/f/factorial_divisor_composite_k.v`](../../../v/f/factorial_divisor_composite_k.v) |
| Zig | [`zig/f/factorial_divisor_composite_k.zig`](../../../zig/f/factorial_divisor_composite_k.zig) |
