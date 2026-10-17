# Matrix exponentiation for a linear recurrence

This benchmark ports the pinned C++ `ans`, `multiply`, and `power` implementation for an order-`k` linear recurrence. It uses the C++ source only and excludes similarly named implementations in other languages.

## Contract

- The ABI is `i64_array_scalar`. Input is `[k, B[0..k), C[0..k), n]` as signed-i64 values, with exactly `2*k + 2` elements. The order `k` is 1–8, each initial value in `B` and coefficient in `C` is in `0..1,000,000,006`, and `n` is in `0..1,000,000,000,000`. The modulus is 1,000,000,007.
- For `n = 0`, the source returns `0`. For `1 <= n <= k`, it returns `B[n-1]` directly. For larger indices, the recurrence is `a_n = C[0]*a_(n-1) + C[1]*a_(n-2) + ... + C[k-1]*a_(n-k)` modulo the fixed modulus. The source builds the companion matrix with ones on the superdiagonal and the coefficients reversed in the last row, raises it to `n-1`, then returns the first row dotted with `B` modulo the fixed modulus.
- The matrix power follows the source recursion: exponent 1 returns the matrix, odd exponents multiply the matrix by the recursively computed exponent-minus-one power, and even exponents square the half power. Matrix multiplication reduces each product and running sum modulo `1,000,000,007`. Canonical input residues keep each signed-i64 product within range. The result is a signed-i64 residue; malformed or out-of-domain input returns `-1`.

The workload covers `n = 0`, direct initial-value cases, order-one and higher-order recurrences, recursive odd/even powers, coefficient and value residues at the modulus boundary, the maximum index, and malformed lengths or values. See [workload.json](workload.json) and the independent [oracle](../../matrix_exponentiation_oracle.py).

Pinned source: [TheAlgorithms/C-Plus-Plus `matrix_exponentiation.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/others/matrix_exponentiation.cpp), functions `ans`, `multiply`, and `power`, at commit `fdcc29b0ac2848e9d1a8d926e171cc5b39f97759`.

## Reproduce

~~~
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm matrix_exponentiation --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/m/matrix_exponentiation/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms matrix_exponentiation --languages rust
~~~

## Language ports

| Language | Source |
| --- | --- |
| C | [c/m/matrix_exponentiation.c](../../../c/m/matrix_exponentiation.c) |
| C3 | [c3/m/matrix_exponentiation.c3](../../../c3/m/matrix_exponentiation.c3) |
| C++ | [cpp/m/matrix_exponentiation.cpp](../../../cpp/m/matrix_exponentiation.cpp) |
| Elisa | [elisa/m/matrix_exponentiation.elisa](../../../elisa/m/matrix_exponentiation.elisa) |
| Nim | [nim/m/matrix_exponentiation.nim](../../../nim/m/matrix_exponentiation.nim) |
| Odin | [odin/m/matrix_exponentiation.odin](../../../odin/m/matrix_exponentiation.odin) |
| Rust | [rust/m/matrix_exponentiation.rs](../../../rust/m/matrix_exponentiation.rs) |
| V | [v/m/matrix_exponentiation.v](../../../v/m/matrix_exponentiation.v) |
| Zig | [zig/m/matrix_exponentiation.zig](../../../zig/m/matrix_exponentiation.zig) |
