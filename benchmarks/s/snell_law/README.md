# Snell's Law Refraction Angle

This benchmark ports the pinned Java method for refraction through an interface between two media. It computes the refracted angle in radians using Snell's law.

## Contract

- The `float64_triple` ABI supplies `[n1, n2, theta1]`, where `n1` and `n2` are finite refractive indices in `[0.5, 2.5]`, and `theta1` is a finite incident angle in radians in `[-π/2, π/2]`.
- Preserve the source operation order: compute `ratio = n1 / n2`, then `sinTheta2 = ratio * sin(theta1)`. Return `asin(sinTheta2)` when `abs(sinTheta2) <= 1`.
- Total internal reflection (`abs(sinTheta2) > 1`) and inputs outside the contract return `-1e300`. Valid angles lie in `[-π/2, π/2]` and use relative and absolute tolerance `1e-12`.

The Python sibling `snells_law` uses a degree-valued angle and rounds the result to two decimal places. It is a related representation variant, not an exact oracle for this Java-radian contract.

## Sources

- [TheAlgorithms/Java `SnellLaw.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/physics/SnellLaw.java)
- [TheAlgorithms/Python `snells_law.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/snells_law.py) (degree-based, rounded sibling)

## Workload and build

[`workload.json`](workload.json) covers equal indices, refraction into a higher index, refraction into a lower index, and total internal reflection. Build with the `float64_triple` ABI and record with `benchmarks/run_float64_triple.py`.

```sh
python3 benchmarks/build_abi.py --family float64_triple --algorithm snell_law --language rust
python3 benchmarks/run_float64_triple.py --build-manifest build/float64_triple/s/snell_law/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/s/snell_law.c`](../../../c/s/snell_law.c) |
| C3 | [`c3/s/snell_law.c3`](../../../c3/s/snell_law.c3) |
| C++ | [`cpp/s/snell_law.cpp`](../../../cpp/s/snell_law.cpp) |
| Elisa | [`elisa/s/snell_law.elisa`](../../../elisa/s/snell_law.elisa) |
| Nim | [`nim/s/snell_law.nim`](../../../nim/s/snell_law.nim) |
| Odin | [`odin/s/snell_law.odin`](../../../odin/s/snell_law.odin) |
| Rust | [`rust/s/snell_law.rs`](../../../rust/s/snell_law.rs) |
| V | [`v/s/snell_law.v`](../../../v/s/snell_law.v) |
| Zig | [`zig/s/snell_law.zig`](../../../zig/s/snell_law.zig) |
