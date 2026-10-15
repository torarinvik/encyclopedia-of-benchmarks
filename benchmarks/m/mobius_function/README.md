# Möbius Function

This benchmark returns the Möbius value `μ(n)` for a positive integer. The pinned Java implementation is the canonical source contract; the pinned JavaScript and Python implementations agree on this positive domain.

## Contract

- The scalar input is an integer `n` in `1..=10,000`.
- Return `0` if a prime square divides `n`. Otherwise return `1` when `n` has an even number of distinct prime factors, and `-1` when it has an odd number. The empty factorization of `1` has even parity, so `μ(1)=1`.
- Inputs outside the supported range return `INT64_MIN`. The Java and JavaScript sources reject nonpositive inputs, while the Python helper has different negative-input behavior; nonpositive inputs are excluded from the source-comparison domain.
- The implementation counts each prime factor once. Repeated divisibility by the same prime returns zero immediately.

The source `mobius` candidate in Go (`math/mobius.go`) is the same function on positive inputs: it returns `1` for `1` and uses the same repeated-prime-square test and distinct-factor parity. Its `n <= 1` shortcut differs outside this benchmark's positive domain. The separate `liouville_lambda` benchmark counts prime factors with multiplicity and is not the Möbius function. Prime-factorization benchmarks return factor data instead of `μ(n)`.

## Sources

- [TheAlgorithms/Java `MobiusFunction.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/Prime/MobiusFunction.java)
- [TheAlgorithms/JavaScript `MobiusFunction.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/MobiusFunction.js)
- [TheAlgorithms/Python `mobius_function.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/mobius_function.py)
- [TheAlgorithms/Go `mobius.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/mobius.go) (same positive-domain contract; catalog alias candidate `mobius`)

## Workload and build

[`workload.json`](workload.json) covers `1`, prime and square-free composites, repeated prime factors, the upper bound, and normalized invalid inputs. All nine ports use the scalar signed 64-bit ABI. The source-backed expected-value check is in [`benchmarks/run_scalar.py`](../../run_scalar.py).

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm mobius_function --language rust
python3 benchmarks/run_scalar.py --build-manifest build/scalar/m/mobius_function/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/m/mobius_function.c`](../../../c/m/mobius_function.c) |
| C3 | [`c3/m/mobius_function.c3`](../../../c3/m/mobius_function.c3) |
| C++ | [`cpp/m/mobius_function.cpp`](../../../cpp/m/mobius_function.cpp) |
| Elisa | [`elisa/m/mobius_function.elisa`](../../../elisa/m/mobius_function.elisa) |
| Nim | [`nim/m/mobius_function.nim`](../../../nim/m/mobius_function.nim) |
| Odin | [`odin/m/mobius_function.odin`](../../../odin/m/mobius_function.odin) |
| Rust | [`rust/m/mobius_function.rs`](../../../rust/m/mobius_function.rs) |
| V | [`v/m/mobius_function.v`](../../../v/m/mobius_function.v) |
| Zig | [`zig/m/mobius_function.zig`](../../../zig/m/mobius_function.zig) |
