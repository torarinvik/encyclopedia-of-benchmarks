# Least common multiple

The least common multiple of two nonnegative integers is the smallest nonnegative value divisible by both. The pinned C source evaluates `(a * b) / gcd(a, b)` using signed `int`; the Go source multiplies `int64` values before converting the product to floating point, which can lose integer precision. Ruby's arbitrary-precision integers avoid fixed-width product overflow ([C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/math/lcm.c), [Go](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/lcm/lcm.go), [Ruby](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/discrete_mathematics/lcm.rb)), and [JavaScript `FindLcm.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/FindLcm.js)). The local ports use one unsigned 64-bit pair ABI and explicitly check the signed 64-bit result range.

## Interface and contract

```c
int64_t lcm(uint64_t left, uint64_t right);
```

Both inputs are in `[0, INT64_MAX]`. The result is nonnegative and fits signed 64-bit. If either input is zero, the result is zero, including `lcm(0, 0)`. If the mathematical result is greater than `INT64_MAX`, the function returns `-1`.

For nonzero inputs, each port computes the Euclidean GCD, divides one input by the GCD, and checks whether multiplying by the other input would exceed `INT64_MAX`. It returns `-1` before multiplication when the result is out of range. This ordering avoids intermediate overflow. The algorithm takes `O(log min(left, right))` iterations and constant auxiliary storage.

## Workload and correctness

[`workload.json`](workload.json) contains 52 pairs for zero inputs, coprime and shared-factor pairs, equal values, large boundaries, and deterministic random values. Thirty-seven published cases have a result beyond signed 64-bit and therefore expect `-1`. The verifier also checks all pairs of 8-bit inputs, boundary patterns, and random 63-bit pairs. Its independent oracle uses Stein's binary GCD and arbitrary-precision multiplication, rather than the ports' Euclidean remainder loop.

Build a port with the shared binary-scalar recipe:

```sh
python3 benchmarks/build_abi.py --family binary_scalar --algorithm lcm --language c
```

Record the published workload from its build manifest:

```sh
python3 benchmarks/run_binary_scalar.py \
  --build-manifest build/binary_scalar/l/lcm/c/build.json
```

Verify LCM in all nine languages with:

```sh
python3 benchmarks/verify_binary_scalar.py \
  --algorithms lcm \
  --elisa-compiler /absolute/path/to/elisac
```

The report is written to `build/binary_scalar/verification.json`. The verification samples check correctness and recording format; they are not performance comparisons.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/l/lcm.c`](../../../c/l/lcm.c) | Portable implementation based on the reviewed C source |
| C3 | [`c3/l/lcm.c3`](../../../c3/l/lcm.c3) | Independent portable implementation |
| C++ | [`cpp/l/lcm.cpp`](../../../cpp/l/lcm.cpp) | Independent portable implementation |
| Elisa | [`elisa/l/lcm.elisa`](../../../elisa/l/lcm.elisa) | Independent portable implementation |
| Nim | [`nim/l/lcm.nim`](../../../nim/l/lcm.nim) | Independent portable implementation |
| Odin | [`odin/l/lcm.odin`](../../../odin/l/lcm.odin) | Independent portable implementation |
| Rust | [`rust/l/lcm.rs`](../../../rust/l/lcm.rs) | Independent portable implementation |
| V | [`v/l/lcm.v`](../../../v/l/lcm.v) | Independent portable implementation |
| Zig | [`zig/l/lcm.zig`](../../../zig/l/lcm.zig) | Independent portable implementation |
