# Sum of binomial coefficients

## Contract

Return the sum of the complete binomial row for `n`:

`C(n, 0) + C(n, 1) + ... + C(n, n) = 2^n`.

The exported C ABI entry point is:

```c
int64_t sum_of_binomial_coefficient(int64_t n);
```

Inputs from `0` through `30` return the exact signed 64-bit value `2^n`. Inputs below zero or above `30` return `-1`. The pinned C++ implementation computes the result with `1 << n`, where `1` has type `int`; limiting `n` to `30` keeps that signed shift defined and positive. The zero case returns one, matching the source expression and the binomial row for `n=0`.

This function sums an entire row; it does not compute one binomial coefficient. Both pinned C++ copies contain the same implementation and source behavior.

## Workload

[`workload.json`](workload.json) covers zero, small and representative rows, the maximum supported shift, and invalid signed inputs. It uses the shared scalar ABI family with one signed 64-bit input and result.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/sum_of_binomial_coefficient.c`](../../../c/s/sum_of_binomial_coefficient.c) |
| C3 | [`c3/s/sum_of_binomial_coefficient.c3`](../../../c3/s/sum_of_binomial_coefficient.c3) |
| C++ | [`cpp/s/sum_of_binomial_coefficient.cpp`](../../../cpp/s/sum_of_binomial_coefficient.cpp) |
| Elisa | [`elisa/s/sum_of_binomial_coefficient.elisa`](../../../elisa/s/sum_of_binomial_coefficient.elisa) |
| Nim | [`nim/s/sum_of_binomial_coefficient.nim`](../../../nim/s/sum_of_binomial_coefficient.nim) |
| Odin | [`odin/s/sum_of_binomial_coefficient.odin`](../../../odin/s/sum_of_binomial_coefficient.odin) |
| Rust | [`rust/s/sum_of_binomial_coefficient.rs`](../../../rust/s/sum_of_binomial_coefficient.rs) |
| V | [`v/s/sum_of_binomial_coefficient.v`](../../../v/s/sum_of_binomial_coefficient.v) |
| Zig | [`zig/s/sum_of_binomial_coefficient.zig`](../../../zig/s/sum_of_binomial_coefficient.zig) |

## Pinned sources

- [C++ `sum_of_binomial_coefficient.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/sum_of_binomial_coefficient.cpp)
- [C++ additional repository `sum_of_binomial_coefficient.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/sum_of_binomial_coefficient.cpp)
