# Aliquot sum

## Contract

Sum the positive proper divisors of `n`, excluding `n` itself. Both zero and one return zero. Negative inputs return `-1`; a sum exceeding signed 64-bit range also returns `-1`. The C ABI accepts and returns signed 64-bit integers.

```c
int64_t aliquot_sum(int64_t n);
```

All nine ports scan candidate divisors from `1` through `n / 2`, matching the linear divisor scan in the reviewed references. The accumulator checks `sum > INT64_MAX - divisor` before addition. There is no multiplication in the scan, and no floating-point arithmetic. The full nonnegative signed 64-bit input range is accepted, although the linear algorithm is expensive for large inputs.

## Upstream review

The C++ example returns zero for zero and one, Nim accepts a positive input type, and Rust panics on zero. The local contract explicitly defines zero, negative inputs, result width, and overflow behavior while preserving the divisor scan.

All local implementations were written independently for this contract. The pinned upstream sources below are discovery and algorithm references.

## Workload and correctness

The workload includes zero and one, primes, squares, perfect numbers, abundant numbers, the amicable pair 220/284, and larger inputs through 99,991. Invalid negative inputs include the minimum signed 64-bit value. Expected values were derived using prime factorization and the multiplicative divisor-sum formula, independently of the benchmark scan.

See [`workload.json`](workload.json). The shared [`scalar runner`](../../harness/scalar_runner.c) uses `-DBENCHMARK_FUNCTION=aliquot_sum`. Each sample contains 32 calls; the workload defaults to two warmup batches and seven samples. Parsing, correctness checks, and serialization are outside timing. [`run_scalar.py`](../../run_scalar.py) records `input_value`, source and build provenance, repetitions, and raw batch durations.

[`verify_scalar.py`](../../verify_scalar.py) builds each implementation, checks a larger deterministic oracle corpus through the real C ABI, and exercises the workload and JSONL recorder. This is a native-host check; it does not establish that every operating system and architecture has been tested.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/a/aliquot_sum.c`](../../../c/a/aliquot_sum.c) | Independent portable implementation |
| C3 | [`c3/a/aliquot_sum.c3`](../../../c3/a/aliquot_sum.c3) | Independent portable implementation |
| C++ | [`cpp/a/aliquot_sum.cpp`](../../../cpp/a/aliquot_sum.cpp) | Independent portable implementation |
| Elisa | [`elisa/a/aliquot_sum.elisa`](../../../elisa/a/aliquot_sum.elisa) | Independent portable implementation |
| Nim | [`nim/a/aliquot_sum.nim`](../../../nim/a/aliquot_sum.nim) | Independent portable implementation |
| Odin | [`odin/a/aliquot_sum.odin`](../../../odin/a/aliquot_sum.odin) | Independent portable implementation |
| Rust | [`rust/a/aliquot_sum.rs`](../../../rust/a/aliquot_sum.rs) | Independent portable implementation |
| V | [`v/a/aliquot_sum.v`](../../../v/a/aliquot_sum.v) | Independent portable implementation |
| Zig | [`zig/a/aliquot_sum.zig`](../../../zig/a/aliquot_sum.zig) | Independent portable implementation |

## TheAlgorithms references

- [C++ `math/aliquot_sum.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/aliquot_sum.cpp)
- [Nim `maths/aliquot_sum.nim`](https://github.com/TheAlgorithms/Nim/blob/63eec16614b46c91078653e8d3c049fe99ad36b3/maths/aliquot_sum.nim)
- [Rust `src/math/aliquot_sum.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/aliquot_sum.rs)
