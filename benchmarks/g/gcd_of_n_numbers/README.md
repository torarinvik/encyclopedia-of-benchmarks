# GCD of N numbers

This benchmark folds a nonempty array of positive signed 32-bit integers with pairwise Euclidean GCD. The input is limited to 64 values, each in `1..=2^31-1`; malformed input returns `-1`. Restricting the common domain to positive values avoids the different zero and empty-array conventions used by the pinned sources.

The pinned C++ implementation folds pairwise Euclidean GCD, and the Rust implementation recursively combines pairwise GCD values. The Python source factors each value into primes and intersects the factor counts. This benchmark standardizes the pairwise Euclidean fold represented by the C++ source and ports it to all nine target languages. Build with the `i64_array_scalar` ABI. Run `python3 benchmarks/verify_gcd_of_n_numbers.py` to check every port against the integer GCD oracle.

## Upstream references

- [C++ `gcd_of_n_numbers.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/gcd_of_n_numbers.cpp)
- [Additional C++ source](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/gcd_of_n_numbers.cpp)
- [Python `gcd_of_n_numbers.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/gcd_of_n_numbers.py)
- [Rust `gcd_of_n_numbers.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/gcd_of_n_numbers.rs)
