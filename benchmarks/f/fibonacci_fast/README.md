# Fast Fibonacci

This benchmark computes the zero-based Fibonacci number with fast doubling in `O(log n)` time. It accepts indices from `0` through `92`, where the result fits in a signed 64-bit integer; other inputs return `-1`. The local implementation uses fixed-width 64-bit unsigned intermediates so the benchmark behaves the same on platforms where C `unsigned long` has different widths.

The pinned C source uses recursive fast doubling. The pinned C++ file with the same name uses a stateful linear recurrence, so this benchmark selects the C algorithm's logarithmic method and ports its formulas across all nine target languages. Build with the `scalar` ABI. Run `python3 benchmarks/verify_scalar.py --algorithms fibonacci_fast` to check the ports against an independent exact fast-doubling oracle.

## Upstream references

- [C `fibonacci_fast.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/math/fibonacci_fast.c)
- [C++ `fibonacci_fast.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/fibonacci_fast.cpp)
- [Additional C++ source](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/fibonacci_fast.cpp)
