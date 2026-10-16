# Gaussian Density

This benchmark ports the pinned Python scalar Gaussian density function. It evaluates the normal-distribution density at `x` for mean `mu` and standard deviation `sigma`.

## Contract

- The `i64_array_float64` ABI supplies exactly `[x, mu, sigma]` as signed 64-bit integers. Require `x` and `mu` in `[-100,100]` and `sigma` in `[1,100]`. The integer subset keeps the packed inputs exact and excludes the source's zero-standard-deviation singularity.
- Preserve the source expression order: `1 / sqrt(2*pi*sigma**2) * exp(-((x-mu)**2)/(2*sigma**2))`. Use binary64 math; results use relative and absolute tolerance `1e-12`. Large separation may underflow to zero as in the source.
- Malformed inputs or values outside these bounds return `-1e300`.

The catalog also groups Java `Gaussian.java`, but that class performs a Gaussian-elimination routine and has different inputs and outputs. This package follows the scalar density function in Python `gaussian.py`; the Java file is a name match, not a semantic implementation of this function. This is distinct from the Gaussian error linear unit activation and Gaussian elimination benchmarks.

## Source

- [TheAlgorithms/Python `maths/gaussian.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/gaussian.py)

## Workload and build

[`workload.json`](workload.json) covers the standard normal peak, symmetric offsets, changed mean and deviation, underflow, the upper deviation bound, and invalid inputs. The shared `i64_array_float64` runner validates cases against [`gaussian_oracle.py`](../../gaussian_oracle.py).

## Ports

| Language | Source |
| --- | --- |
| C | [`c/g/gaussian.c`](../../../c/g/gaussian.c) |
| C3 | [`c3/g/gaussian.c3`](../../../c3/g/gaussian.c3) |
| C++ | [`cpp/g/gaussian.cpp`](../../../cpp/g/gaussian.cpp) |
| Elisa | [`elisa/g/gaussian.elisa`](../../../elisa/g/gaussian.elisa) |
| Nim | [`nim/g/gaussian.nim`](../../../nim/g/gaussian.nim) |
| Odin | [`odin/g/gaussian.odin`](../../../odin/g/gaussian.odin) |
| Rust | [`rust/g/gaussian.rs`](../../../rust/g/gaussian.rs) |
| V | [`v/g/gaussian.v`](../../../v/g/gaussian.v) |
| Zig | [`zig/g/gaussian.zig`](../../../zig/g/gaussian.zig) |

Build and record an implementation with:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm gaussian --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/g/gaussian/rust/build.json
```
