# Divisors

This benchmark follows `divisors(n)` from the pinned Julia
[`divisors.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/divisors.jl).
The source returns every positive divisor of a positive integer in ascending
order.

## Contract

- Input is exactly `[n]`, with `1 <= n <= 62`. The source throws for values
  less than or equal to zero; this bounded ABI represents those and malformed
  inputs with `-1`.
- The scalar result is a lossless bit mask for the divisor set: bit `d` is set
  exactly when `d` divides `n`. Thus the source's sorted vector is recoverable
  by reading set bits in increasing order. This representation keeps the full
  result distinct from divisor-count and divisor-sum benchmarks.
- The upper bound keeps bit 62 within the positive signed 64-bit range. The
  parser accepts two values so a complete one-extra-value malformed input can
  be represented.

The independent oracle discovers divisor pairs up to the square root and
packs the resulting set; it does not repeat the source's linear scan from 1
through `n`. The workload covers 1, primes, perfect squares, composite values,
the upper boundary, zero/negative values, and malformed lengths.

## Pinned source

Julia [`divisors.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/divisors.jl)
at commit `384424b762bbb40d43f31001beeca0c6ffda2f1f`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/d/divisors.c`](../../../c/d/divisors.c) |
| C3 | [`c3/d/divisors.c3`](../../../c3/d/divisors.c3) |
| C++ | [`cpp/d/divisors.cpp`](../../../cpp/d/divisors.cpp) |
| Elisa | [`elisa/d/divisors.elisa`](../../../elisa/d/divisors.elisa) |
| Nim | [`nim/d/divisors.nim`](../../../nim/d/divisors.nim) |
| Odin | [`odin/d/divisors.odin`](../../../odin/d/divisors.odin) |
| Rust | [`rust/d/divisors.rs`](../../../rust/d/divisors.rs) |
| V | [`v/d/divisors.v`](../../../v/d/divisors.v) |
| Zig | [`zig/d/divisors.zig`](../../../zig/d/divisors.zig) |

The workload is [`workload.json`](workload.json), and the independent oracle
is [`divisors_oracle.py`](../../divisors_oracle.py).
