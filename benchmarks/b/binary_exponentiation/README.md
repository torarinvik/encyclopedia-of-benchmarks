# Binary exponentiation

Binary exponentiation computes an integer power by squaring the base and consuming the exponent’s bits. The pinned Rust and Java sources use integer powers, while Python and C++ provide iterative and recursive variants with related real-number APIs. This benchmark standardizes exact nonnegative integer powers and overflow behavior.

## Contract

The packed signed 64-bit input is `[base, exponent]`. Both values are nonnegative signed 32-bit integers. The result is the exact power when it fits in signed 64-bit; invalid input or a result above `2^63-1` returns `-1`. The base is nonnegative so the sentinel cannot collide with a valid result. `0^0` is defined as 1.

Each port uses exponentiation by squaring and checks multiplication bounds before multiplying. Runtime is O(log exponent), with O(1) extra storage.

## Reproduce

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm binary_exponentiation --language c
python3 benchmarks/run_i64_array_scalar.py --algorithm binary_exponentiation
python3 benchmarks/verify_binary_exponentiation.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1
```

The verifier compares with an overflow-aware arbitrary-precision oracle over exhaustive small inputs, randomized values, signed boundaries, overflow boundaries, and the published workload.

Upstream references: [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/binary_exponentiation.py), [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/binary_exponentiation.rs), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/divideandconquer/BinaryExponentiation.java), [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/fast_power.cpp), and JavaScript's recursive [`BinaryExponentiationRecursive.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/BinaryExponentiationRecursive.js).
