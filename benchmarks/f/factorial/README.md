# Factorial

## Contract

Compute `n!` using the standard definition, with `0! = 1`. Inputs from `0` through `20` return the exact result as a signed 64-bit integer. Inputs outside that range return `-1`; this keeps negative inputs and values whose results exceed the ABI range well-defined.

The exported C ABI entry point is:

```c
int64_t factorial(int64_t n);
```

The local implementations use an iterative product loop. This is a shared benchmark contract across languages; upstream files vary in API and implementation. The inspected C source prints arbitrary-precision decimal digits, while the C++ source uses recursion and caps its input at 20.

## Workload and measurement

[`workload.json`](workload.json) covers zero, one, representative values, the maximum supported input, a negative input, and the first out-of-range value. The C11 scalar runner checks each expected result before timing, runs two warmup batches, then records seven samples of 10,000 calls each. Input parsing, correctness checks, and JSON writing are outside the timed interval.

Compile [`benchmarks/harness/scalar_runner.c`](../../harness/scalar_runner.c) with `-DBENCHMARK_FUNCTION=factorial`. [`benchmarks/run_scalar.py`](../../run_scalar.py) appends one JSON Lines record per workload case using [`benchmarks/results.schema.json`](../../results.schema.json). Scalar records use `input_length: null` and put `n` in `input_value`.

[`build_scalar.py`](../../build_scalar.py) provides the standalone build recipe for all nine languages. [`verify_scalar.py`](../../verify_scalar.py) checks every valid input from 0 through 20 against `math.factorial`, supplements them with invalid and signed-width boundary inputs, and exercises the JSONL recording flow through the native C ABI. The resulting report identifies the host and source hashes; it does not claim that every platform has been tested.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/f/factorial.c`](../../../c/f/factorial.c) | Independent portable implementation; TheAlgorithms C reference below |
| C3 | [`c3/f/factorial.c3`](../../../c3/f/factorial.c3) | Local port |
| C++ | [`cpp/f/factorial.cpp`](../../../cpp/f/factorial.cpp) | Independent portable implementation; TheAlgorithms C++ reference below |
| Elisa | [`elisa/f/factorial.elisa`](../../../elisa/f/factorial.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/f/factorial.nim`](../../../nim/f/factorial.nim) | Local port |
| Odin | [`odin/f/factorial.odin`](../../../odin/f/factorial.odin) | Local port |
| Rust | [`rust/f/factorial.rs`](../../../rust/f/factorial.rs) | Independent portable implementation; TheAlgorithms Rust reference below |
| V | [`v/f/factorial.v`](../../../v/f/factorial.v) | Local port |
| Zig | [`zig/f/factorial.zig`](../../../zig/f/factorial.zig) | Independent portable implementation; TheAlgorithms Zig reference below |

All local code was written independently under the shared contract.

## TheAlgorithms references

- [C `factorial.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/math/factorial.c)
- [C++ `factorial.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/factorial.cpp)
- [Rust `factorial.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/factorial.rs)
- [Zig `factorial.zig`](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/math/factorial.zig)
