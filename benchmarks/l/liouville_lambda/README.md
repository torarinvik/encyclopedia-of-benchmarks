# Liouville function

The pinned Python source defines Liouville's function by counting prime factors with multiplicity. This benchmark keeps that definition and uses integer trial division in all nine portable ports.

## Contract

- Input is a signed 64-bit integer `n` from 1 through 2,147,483,647.
- Return `(-1)^Ω(n)`, where `Ω(n)` is the total number of prime factors counting multiplicity.
- Return `-1` outside the supported input range. The pinned sources reject invalid values; this benchmark uses `-1` as its adapter sentinel.
- `λ(1) = 1` because 1 has no prime factors.

For example, `λ(4) = 1` because `4 = 2×2` has two prime factors with multiplicity. This distinguishes Liouville's function from the Möbius function, which returns zero for nonsquarefree inputs such as 4.

The common upper bound matches Java's positive signed-32-bit input domain and keeps the JavaScript `Number` input exact. The input range also matches the repository's `prime_factors` benchmark. Each implementation uses overflow-safe integer trial division (`factor <= remaining / factor`) and toggles the sign for every occurrence of a factor.

## Workload

[`workload.json`](workload.json) includes 1, prime and composite inputs, repeated prime factors, a large prime, the upper bound, and values outside the supported range.

## Upstream sources

- [TheAlgorithms/Python `liouville_lambda.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/liouville_lambda.py)
- [TheAlgorithms/Python `prime_factors.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/prime_factors.py)
- [TheAlgorithms/Java `LiouvilleLambdaFunction.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/Prime/LiouvilleLambdaFunction.java)
- [TheAlgorithms/JavaScript `LiouvilleFunction.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/LiouvilleFunction.js)

The Java and JavaScript candidates are aliases of this benchmark: both compute the parity of prime-factor multiplicities on the shared positive input domain. The similarly named Go candidate is a different function: it counts distinct prime factors, so for example it returns `-1` for 4 while this benchmark returns `1`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/l/liouville_lambda.c`](../../../c/l/liouville_lambda.c) |
| C3 | [`c3/l/liouville_lambda.c3`](../../../c3/l/liouville_lambda.c3) |
| C++ | [`cpp/l/liouville_lambda.cpp`](../../../cpp/l/liouville_lambda.cpp) |
| Elisa | [`elisa/l/liouville_lambda.elisa`](../../../elisa/l/liouville_lambda.elisa) |
| Nim | [`nim/l/liouville_lambda.nim`](../../../nim/l/liouville_lambda.nim) |
| Odin | [`odin/l/liouville_lambda.odin`](../../../odin/l/liouville_lambda.odin) |
| Rust | [`rust/l/liouville_lambda.rs`](../../../rust/l/liouville_lambda.rs) |
| V | [`v/l/liouville_lambda.v`](../../../v/l/liouville_lambda.v) |
| Zig | [`zig/l/liouville_lambda.zig`](../../../zig/l/liouville_lambda.zig) |

## Build and verify

```sh
python3 benchmarks/build_scalar.py --algorithm liouville_lambda --language rust
python3 benchmarks/run_scalar.py --build-manifest build/scalar/l/liouville_lambda/rust/build.json
python3 benchmarks/verify_scalar.py --algorithms liouville_lambda
```
