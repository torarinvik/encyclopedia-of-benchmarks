# Sum of a multiplicative function (large)

This benchmark implements the Min_25 sieve for the multiplicative function defined by `f(p^e) = a*e + b*p` on prime powers. It returns `sum(f(i), 1 <= i <= N) mod 469762049`.

## Contract

- Input is a three-element signed 64-bit array `[N, a, b]`.
- Exactly three values are valid; the parser accepts up to four values so the workload can include one parseable extra-value rejection.
- Require `1 <= N <= 100,000,000` and `0 <= a,b < 469762049`. Invalid length or values return `-1`.
- The local cap is lower than Library Checker's `N <= 10^13` limit to bound table memory across the language ports. The official task also constrains `T <= 10,000`, `T*sqrt(N) <= 1,000,000` when `T > 1`, and uses `MOD = 469762049`.
- `f` is multiplicative, `f(1)=1`, and for each prime `p` and exponent `e>=1`, `f(p^e)=a*e+b*p` modulo `MOD`.
- The official input groups up to `T` triples. The scalar-array package treats each triple as one call with `[N, a, b]`.

The Min_25 sieve first computes prime counts and prime sums for the distinct values `floor(N/i)`, combines them to get the prime prefix sums of `f`, then adds prime-power and composite contributions in descending-prime order. This is distinct from the local summatory-totient benchmark, which handles only `phi` with a quotient-block recurrence, and from divisor/totient packages that compute specific functions.

The independent oracle factors values directly in bounded segments, without using Min_25. The workload's maximum-`N` case uses `a=b=0`, where every `f(n)` for `n>1` is zero and the answer is exactly one.

## Workload

[`workload.json`](workload.json) covers `f(1)`, `tau(n)` (`a=1,b=0`), the radical function (`a=0,b=1`), mixed prime-power terms, a large input, and invalid values.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm sum_of_multiplicative_function_large --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/s/sum_of_multiplicative_function_large/rust/build.json
```

## Source

- [Library Checker task statement](https://github.com/yosupo06/library-checker-problems/blob/master/number_theory/sum_of_multiplicative_function_large/task.md)
- [Library Checker Min_25 solution](https://github.com/yosupo06/library-checker-problems/blob/master/number_theory/sum_of_multiplicative_function_large/sol/min_25_sieve.cpp)

## Implementations

The nine standard ports and optional Mojo port use the shared array-scalar ABI:

| Language | Source |
|---|---|
| C | `c/s/sum_of_multiplicative_function_large.c` |
| C3 | `c3/s/sum_of_multiplicative_function_large.c3` |
| C++ | `cpp/s/sum_of_multiplicative_function_large.cpp` |
| Elisa | `elisa/s/sum_of_multiplicative_function_large.elisa` |
| Nim | `nim/s/sum_of_multiplicative_function_large.nim` |
| Odin | `odin/s/sum_of_multiplicative_function_large.odin` |
| Rust | `rust/s/sum_of_multiplicative_function_large.rs` |
| V | `v/s/sum_of_multiplicative_function_large.v` |
| Zig | `zig/s/sum_of_multiplicative_function_large.zig` |
| Mojo | `mojo/s/sum_of_multiplicative_function_large.mojo` |
