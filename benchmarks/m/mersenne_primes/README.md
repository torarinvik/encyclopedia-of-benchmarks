# Mersenne primes

This package ports the pinned Rust [`is_mersenne_prime`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74a939ec5163648458a8c2b46fd4c/src/math/mersenne_primes.rs) predicate. It checks whether the Mersenne number `2^n - 1` is prime using the Lucas–Lehmer recurrence. The separate `get_mersenne_primes` list-generation function is outside this benchmark.

## Contract

The `scalar_call` input is an exponent `n` in `2..31`. For `n = 2`, the source returns true directly. Otherwise it initializes `s = 4` and performs `n - 2` rounds of `s = (s*s - 2) mod (2^n - 1)`, returning 1 exactly when the final residue is zero. This preserves the source behavior for composite exponents too: they are valid inputs and normally return 0. Inputs outside `2..31` return -1.

The bound keeps `2^n - 1` within signed 32-bit range and every recurrence product within signed 64-bit range. The independent oracle checks primality of `2^n - 1` by trial division rather than using Lucas–Lehmer.

See [`workload.json`](workload.json) and [`mersenne_primes_oracle.py`](../../mersenne_primes_oracle.py).

| Language | Port |
|---|---|
| C | [`c/m/mersenne_primes.c`](../../../c/m/mersenne_primes.c) |
| C3 | [`c3/m/mersenne_primes.c3`](../../../c3/m/mersenne_primes.c3) |
| C++ | [`cpp/m/mersenne_primes.cpp`](../../../cpp/m/mersenne_primes.cpp) |
| Elisa | [`elisa/m/mersenne_primes.elisa`](../../../elisa/m/mersenne_primes.elisa) |
| Nim | [`nim/m/mersenne_primes.nim`](../../../nim/m/mersenne_primes.nim) |
| Odin | [`odin/m/mersenne_primes.odin`](../../../odin/m/mersenne_primes.odin) |
| Rust | [`rust/m/mersenne_primes.rs`](../../../rust/m/mersenne_primes.rs) |
| V | [`v/m/mersenne_primes.v`](../../../v/m/mersenne_primes.v) |
| Zig | [`zig/m/mersenne_primes.zig`](../../../zig/m/mersenne_primes.zig) |
