# Armstrong number

## Contract

Return `1` exactly when the nonnegative input equals the sum of its decimal digits, each raised to the number of digits; return `0` otherwise. Zero and all positive single-digit inputs are Armstrong numbers. Negative inputs return zero. Input and result use signed 64-bit integers.

```c
int64_t armstrong_number(int64_t n);
```

All nine ports count decimal digits by division, calculate each digit power by repeated integer multiplication, and accumulate the powers. A signed 64-bit nonnegative input has at most 19 digits, so each power is at most `9^19 = 1350851717672992089`, which fits the result type. Before adding a term, the code checks `power > n - sum` and rejects immediately when the total would exceed the input. This prevents accumulator overflow even when the mathematical sum exceeds `INT64_MAX`.

## Upstream review

The C reference uses integer exponentiation and an `int` input; C++ uses floating-point `std::pow` and handles negative values; Rust uses unsigned 32-bit digits and powers. The local contract uses the full signed 64-bit input range, exact integer arithmetic, and an integer predicate result.

All local implementations were written independently for this contract. The pinned upstream sources below are discovery and algorithm references.

## Workload and correctness

The workload includes zero, single-digit values, known positive examples and their neighbors, 10-digit and 19-digit positive examples, negative inputs, and large inputs whose digit-power sums may exceed signed 64-bit range. Expected results were derived with Python arbitrary-precision arithmetic on decimal strings.

See [`workload.json`](workload.json). The shared [`scalar runner`](../../harness/scalar_runner.c) uses `-DBENCHMARK_FUNCTION=armstrong_number`. Each sample contains 10,000 calls; the workload defaults to two warmup batches and seven samples. Parsing, correctness checks, and serialization are outside timing. [`run_scalar.py`](../../run_scalar.py) records `input_value`, source and build provenance, repetitions, and raw batch durations.

[`verify_scalar.py`](../../verify_scalar.py) builds each implementation, checks a larger deterministic oracle corpus through the real C ABI, and exercises the workload and JSONL recorder. This is a native-host check; it does not establish that every operating system and architecture has been tested.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/a/armstrong_number.c`](../../../c/a/armstrong_number.c) | Independent portable implementation |
| C3 | [`c3/a/armstrong_number.c3`](../../../c3/a/armstrong_number.c3) | Independent portable implementation |
| C++ | [`cpp/a/armstrong_number.cpp`](../../../cpp/a/armstrong_number.cpp) | Independent portable implementation |
| Elisa | [`elisa/a/armstrong_number.elisa`](../../../elisa/a/armstrong_number.elisa) | Independent portable implementation |
| Nim | [`nim/a/armstrong_number.nim`](../../../nim/a/armstrong_number.nim) | Independent portable implementation |
| Odin | [`odin/a/armstrong_number.odin`](../../../odin/a/armstrong_number.odin) | Independent portable implementation |
| Rust | [`rust/a/armstrong_number.rs`](../../../rust/a/armstrong_number.rs) | Independent portable implementation |
| V | [`v/a/armstrong_number.v`](../../../v/a/armstrong_number.v) | Independent portable implementation |
| Zig | [`zig/a/armstrong_number.zig`](../../../zig/a/armstrong_number.zig) | Independent portable implementation |

## TheAlgorithms references

- [C `math/armstrong_number.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/math/armstrong_number.c)
- [C++ `math/armstrong_number.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/armstrong_number.cpp)
- [Rust `src/math/armstrong_number.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/armstrong_number.rs)
