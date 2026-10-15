# Fibonacci formula

## Contract

The pinned C function `fib(unsigned int n)` evaluates Binet's formula, stores
the result in a C `float`, then converts that value to `int` by truncation:

```text
float seq = (1 / sqrt(5) * pow((1 + sqrt(5)) / 2, n + 1))
          - (1 / sqrt(5) * pow((1 - sqrt(5)) / 2, n + 1));
return seq;
```

The code uses exponent `n + 1`, so it returns the one-based sequence
`1, 1, 2, 3, ...`; in conventional zero-indexed notation the result is
`F(n + 1)`. This follows the executable source, whose examples give `fib(0) =
1`, even though the comment describes the nth Fibonacci value.

The benchmark accepts `n` in `0..=35`. Through this bound, `F(n + 1)` fits
the source's signed `int` result and is exactly representable as a 32-bit
float. The ports preserve the source's binary64 `sqrt`/`pow` expression order,
round the computed value to binary32, then truncate toward zero to the result
integer. Negative and above-bound ABI inputs return `-1`.

This is an approximation formula benchmark. It is distinct from the
zero-indexed exact recurrence in [`fibonacci`](../fibonacci/README.md), and
from the tabulation strategy in [`fibonacci_dp`](../fibonacci_dp/README.md).
Its output aligns with the exact sequence at index `n + 1` over the bounded
workload, but its source indexing and computation are different.

## Workload and build

[`workload.json`](workload.json) covers the first terms, representative
indices, the largest bounded index, and invalid inputs. It uses the unary
`scalar` ABI.

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm fibonacci_formula --language c
python3 benchmarks/run_scalar.py --build-manifest build/scalar/f/fibonacci_formula/c/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/f/fibonacci_formula.c`](../../../c/f/fibonacci_formula.c) |
| C3 | [`c3/f/fibonacci_formula.c3`](../../../c3/f/fibonacci_formula.c3) |
| C++ | [`cpp/f/fibonacci_formula.cpp`](../../../cpp/f/fibonacci_formula.cpp) |
| Elisa | [`elisa/f/fibonacci_formula.elisa`](../../../elisa/f/fibonacci_formula.elisa) |
| Nim | [`nim/f/fibonacci_formula.nim`](../../../nim/f/fibonacci_formula.nim) |
| Odin | [`odin/f/fibonacci_formula.odin`](../../../odin/f/fibonacci_formula.odin) |
| Rust | [`rust/f/fibonacci_formula.rs`](../../../rust/f/fibonacci_formula.rs) |
| V | [`v/f/fibonacci_formula.v`](../../../v/f/fibonacci_formula.v) |
| Zig | [`zig/f/fibonacci_formula.zig`](../../../zig/f/fibonacci_formula.zig) |

## Pinned source

- [C `fibonacci_formula.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/math/fibonacci_formula.c)
