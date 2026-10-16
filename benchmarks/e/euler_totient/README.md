# Euler totient

Return Euler’s totient `φ(n)`, the number of integers `k` in `1..=n` coprime to `n`. The ports factor `n` and subtract `result / p` once for each distinct prime divisor `p`.

## Contract

- Input is a signed 64-bit integer in `1..=1,000,000`.
- Return `φ(n)`; inputs outside the range return `-1`.
- The result is an exact signed 64-bit integer.

This is the scalar operation. [`compute_totient`](../../c/compute_totient/README.md), [`euler_totient_sequence`](../euler_totient_sequence/README.md), and [`totients_linear_sieve`](../../t/totients_linear_sieve/README.md) return sequences instead. The source algorithms use factorization or count coprimes directly; the bounded contract gives each port the same integer domain.

## Sources and workload

Reviewed scalar sources include [Dart `eulers_totient.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/maths/eulers_totient.dart), [JavaScript `EulersTotient.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/EulersTotient.js), [Julia `eulers_totient.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/eulers_totient.jl), [Rust `euler_totient.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/number_theory/euler_totient.rs), [TypeScript `euler_totient.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/maths/euler_totient.ts), and [Lua `totient.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/math/totient.lua), [Go `eulertotient.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/eulertotient.go), [C++ `eulers_totient_function.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/eulers_totient_function.cpp), and [JavaScript `EulersTotientFunction.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/EulersTotientFunction.js). The Lua source counts coprime values directly; the others use the prime-factor formula. The pinned Python [`basic_maths.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/basic_maths.py) also uses the prime-factor formula as `euler_phi`; its source-domain positive integers map to this benchmark on the bounded range.

[`workload.json`](workload.json) covers one, primes, prime powers, products of distinct primes, a square, the upper bound, and invalid inputs. Build with `python3 benchmarks/build_abi.py --family scalar --algorithm euler_totient --language c`.

| Language | Source |
| --- | --- |
| C | [`c/e/euler_totient.c`](../../../c/e/euler_totient.c) |
| C3 | [`c3/e/euler_totient.c3`](../../../c3/e/euler_totient.c3) |
| C++ | [`cpp/e/euler_totient.cpp`](../../../cpp/e/euler_totient.cpp) |
| Elisa | [`elisa/e/euler_totient.elisa`](../../../elisa/e/euler_totient.elisa) |
| Nim | [`nim/e/euler_totient.nim`](../../../nim/e/euler_totient.nim) |
| Odin | [`odin/e/euler_totient.odin`](../../../odin/e/euler_totient.odin) |
| Rust | [`rust/e/euler_totient.rs`](../../../rust/e/euler_totient.rs) |
| V | [`v/e/euler_totient.v`](../../../v/e/euler_totient.v) |
| Zig | [`zig/e/euler_totient.zig`](../../../zig/e/euler_totient.zig) |
