# Largest prime power dividing a factorial

## Contract

Return the exponent of prime `p` in the prime factorization of `n!`, also written `v_p(n!)`. Legendre's formula computes it as `floor(n/p) + floor(n/p²) + floor(n/p³) + ...` until the quotient reaches zero.

The exported C ABI entry point is:

```c
int64_t largest_power(uint64_t n, uint64_t p);
```

Inputs use the unsigned pair ABI. `n` must be at most `UINT32_MAX`, matching the pinned source's `uint32_t` argument. `p` must be a prime from 2 through 65,535, matching the pinned source's `uint16_t` prime argument and documented prime precondition. Invalid inputs return `-1`. For valid inputs, the result is the exact `v_p(n!)`; `n=0` returns zero.

The pinned C++ function repeatedly divides `n` by `p` and adds each quotient. It assumes that `p` is prime and greater than one and does not validate it; zero or one would fail to make progress. The local ports validate this precondition so invalid ABI inputs return safely. They use the same quotient-sum recurrence, avoiding explicit powers that could overflow.

## Workload

[`workload.json`](workload.json) includes the source examples, zero and small boundaries, several primes, the maximum `n`, and invalid prime/range inputs. It uses the shared `binary_scalar` ABI family: two unsigned 64-bit inputs and one signed 64-bit result.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/l/largest_power.c`](../../../c/l/largest_power.c) |
| C3 | [`c3/l/largest_power.c3`](../../../c3/l/largest_power.c3) |
| C++ | [`cpp/l/largest_power.cpp`](../../../cpp/l/largest_power.cpp) |
| Elisa | [`elisa/l/largest_power.elisa`](../../../elisa/l/largest_power.elisa) |
| Nim | [`nim/l/largest_power.nim`](../../../nim/l/largest_power.nim) |
| Odin | [`odin/l/largest_power.odin`](../../../odin/l/largest_power.odin) |
| Rust | [`rust/l/largest_power.rs`](../../../rust/l/largest_power.rs) |
| V | [`v/l/largest_power.v`](../../../v/l/largest_power.v) |
| Zig | [`zig/l/largest_power.zig`](../../../zig/l/largest_power.zig) |

## Pinned sources

- [C++ `largest_power.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/largest_power.cpp)
- [C++ additional repository `largest_power.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/largest_power.cpp)
