# Fibonacci number by the golden ratio

## Contract

This benchmark follows the pinned Java `fibonacciNumberGoldenRation(int n)`
implementation. It accepts an index `n` from `0` through `70`. For `n` equal
to 0 or 1, the source returns `n` directly. Otherwise it evaluates the Binet
formula in binary64:

```text
sqrt5 = sqrt(5)
phi = (1 + sqrt5) / 2
psi = (1 - sqrt5) / 2
result = (pow(phi, n) - pow(psi, n)) / sqrt5
return Math.round(result)
```

The ports preserve this operation order and Java's `Math.round` behavior. On
this nonnegative domain that is equivalent to rounding with `floor(x + 0.5)`.
The result fits signed 64-bit output through index 70. Inputs outside the
domain return `-1`, matching the source's rejected-input behavior at the ABI.

This is the binary64 Binet implementation. It is distinct from the exact
recurrence in [`fibonacci`](../fibonacci/README.md) and from
[`fibonacci_formula`](../fibonacci_formula/README.md), which uses a binary32
intermediate and evaluates the one-based value `F(n + 1)`.

## Workload and build

[`workload.json`](workload.json) uses the unary `scalar` ABI and covers base
cases, representative indices, the largest supported index, and invalid
inputs.

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm fibonacci_number_golden_ration --language c
python3 benchmarks/run_scalar.py --build-manifest build/scalar/f/fibonacci_number_golden_ration/c/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/f/fibonacci_number_golden_ration.c`](../../../c/f/fibonacci_number_golden_ration.c) |
| C3 | [`c3/f/fibonacci_number_golden_ration.c3`](../../../c3/f/fibonacci_number_golden_ration.c3) |
| C++ | [`cpp/f/fibonacci_number_golden_ration.cpp`](../../../cpp/f/fibonacci_number_golden_ration.cpp) |
| Elisa | [`elisa/f/fibonacci_number_golden_ration.elisa`](../../../elisa/f/fibonacci_number_golden_ration.elisa) |
| Nim | [`nim/f/fibonacci_number_golden_ration.nim`](../../../nim/f/fibonacci_number_golden_ration.nim) |
| Odin | [`odin/f/fibonacci_number_golden_ration.odin`](../../../odin/f/fibonacci_number_golden_ration.odin) |
| Rust | [`rust/f/fibonacci_number_golden_ration.rs`](../../../rust/f/fibonacci_number_golden_ration.rs) |
| V | [`v/f/fibonacci_number_golden_ration.v`](../../../v/f/fibonacci_number_golden_ration.v) |
| Zig | [`zig/f/fibonacci_number_golden_ration.zig`](../../../zig/f/fibonacci_number_golden_ration.zig) |

## Pinned source

- Java [`FibonacciNumberGoldenRation.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/FibonacciNumberGoldenRation.java)
