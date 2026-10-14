# Greatest common divisor

Euclid's algorithm finds the greatest common divisor of two integers by repeatedly replacing `(a, b)` with `(b, a mod b)`. The pinned C example uses recursive Euclid with signed `int` inputs; the Zig example uses an iterative loop with unsigned inputs and asserts that both inputs are not zero ([C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/math/gcd.c), [Zig](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/math/gcd.zig)). The local benchmark standardizes on an iterative, nonnegative 64-bit contract and defines the `(0, 0)` case as zero.

## Interface and contract

```c
int64_t gcd(uint64_t left, uint64_t right);
```

Each input is in `[0, INT64_MAX]`, and the result is a nonnegative signed 64-bit integer. There are no invalid inputs or error results. The function returns `right` when `left` is zero, returns `left` when `right` is zero, and returns zero when both are zero. Otherwise, it repeats Euclid's remainder step until the second value reaches zero. It takes `O(log min(left, right))` iterations and constant auxiliary storage.

The unsigned ABI type keeps modulo behavior well-defined across the nine language FFI boundaries. The workload limits values to the nonnegative signed 64-bit range so every result fits the signed return type.

## Workload and correctness

[`workload.json`](workload.json) contains 52 pairs, including both zero orders, shared factors, coprime and equal inputs, large boundary values, a long Euclidean chain from adjacent Fibonacci numbers, and deterministic random inputs. The verifier adds all pairs of 8-bit inputs, boundary patterns, and random 63-bit pairs. It checks the ports against an independent binary-GCD oracle and records one result per published case.

Build a port with the shared binary-scalar recipe:

```sh
python3 benchmarks/build_abi.py --family binary_scalar --algorithm gcd --language c
```

Record the workload using its build manifest:

```sh
python3 benchmarks/run_binary_scalar.py \
  --build-manifest build/binary_scalar/g/gcd/c/build.json
```

Verify all nine languages, including Elisa, with:

```sh
python3 benchmarks/verify_binary_scalar.py \
  --algorithms gcd \
  --elisa-compiler /absolute/path/to/elisac
```

The verifier writes its report to `build/binary_scalar/verification.json`. These one-sample checks validate correctness and result recording, not comparative performance.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/g/gcd.c`](../../../c/g/gcd.c) | Portable adaptation of the C Euclidean algorithm |
| C3 | [`c3/g/gcd.c3`](../../../c3/g/gcd.c3) | Independent portable implementation |
| C++ | [`cpp/g/gcd.cpp`](../../../cpp/g/gcd.cpp) | Independent portable implementation |
| Elisa | [`elisa/g/gcd.elisa`](../../../elisa/g/gcd.elisa) | Independent portable implementation |
| Nim | [`nim/g/gcd.nim`](../../../nim/g/gcd.nim) | Independent portable implementation |
| Odin | [`odin/g/gcd.odin`](../../../odin/g/gcd.odin) | Independent portable implementation |
| Rust | [`rust/g/gcd.rs`](../../../rust/g/gcd.rs) | Independent portable implementation |
| V | [`v/g/gcd.v`](../../../v/g/gcd.v) | Independent portable implementation |
| Zig | [`zig/g/gcd.zig`](../../../zig/g/gcd.zig) | Portable adaptation of the Zig Euclidean algorithm |
