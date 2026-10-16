# Integral approximation

This benchmark ports the pinned C++ `integral_approx` Riemann-sum routine with its explicit step width and truncating step count. Input is `[function_id, lower_eighths, upper_eighths, delta_eighths]`; bounds and step width are integer multiples of 1/8, `0 <= lower < upper <= 4`, and `1 <= delta <= 8` eighths. Function 0 is `x²`; function 1 is `x³ - x² + 378`, both taken from the source's examples.

The routine computes `numDeltas = uint64((upper-lower)/delta)` and accumulates `delta * (f(begin)+f(end))/2` in increasing step order. Any fractional final step is omitted, as in the source. Invalid input returns `-1e300`; valid output is binary64 with absolute tolerance 1e-12. See the [pinned C++ source](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/integral_approximation.cpp).
