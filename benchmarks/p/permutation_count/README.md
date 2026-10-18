# Permutation count

This package covers the Julia `permutation(n, r)` count variant from the broader `permutation` candidate. It remains separate from the C# unique-string enumeration and Java duplicate-preserving array enumeration.

## Contract

The `i64_array_scalar` ABI accepts exactly `[n, r]`, with each value in `0..18`. It returns the source expression `factorial(n) / factorial(n - r)` as an integer. This bound keeps every factorial numerator at or below `18!`, which is exactly representable in Float64 and fits signed i64; the pinned Julia routine's `/` therefore produces an exact integral value throughout the domain.

The source helper initializes the factorial to 1 and multiplies over `1:value`. A negative argument makes that ascending range empty, so for `r > n` the denominator is 1 and the source returns `n!`. The benchmark preserves that bounded edge behavior. Negative `n` or `r`, values above 18, malformed input length, and signed-i64 overflow values return `-1`.

## Pinned source

The source is [`permutation(n, r)`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/permutation.jl) in TheAlgorithms/Julia at commit `384424b762bbb40d43f31001beeca0c6ffda2f1f`. It computes `factorial(n) / factorial(n - r)` and converts the result to `Int64`.

See the [workload](workload.json) and [oracle](../../permutation_count_oracle.py).
