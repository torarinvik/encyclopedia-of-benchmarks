# Center of mass

This package ports the pinned Python discrete-particle center-of-mass calculation. It computes the mass-weighted average of one selected coordinate and rounds the result to two decimal places, preserving the source's binary64 summation and Python rounding behavior.

## Contract

The signed-i64 array is laid out as `[coordinate_selector, particle_count, x1_milli, y1_milli, z1_milli, mass1_milli, ...]`. The selector is `0` for x, `1` for y, or `2` for z. The particle count is from 1 through 64. Coordinate and mass values are scaled by 1,000, so an integer value of 1,500 represents 1.5. Coordinates are bounded to `[-1,000,000, 1,000,000]` scaled units, and masses to `[1, 1,000,000]` scaled units. These bounds represent coordinates from -1,000 through 1,000 and strictly positive masses from 0.001 through 1,000.

For valid input, return the selected component of `round(sum(coordinate * mass) / sum(mass), 2)`, using the source's particle order. Invalid selectors, counts, shapes, coordinate bounds, or nonpositive/out-of-range masses return `-1e300`. This sentinel stands in for the source's `ValueError` on empty input or invalid masses; valid results are always between -1,000 and 1,000. The largest input has 258 values.

The C ABI is:

```c
double center_of_mass(const int64_t *values, size_t length);
```

## Workload and verification

[`workload.json`](workload.json) includes both pinned examples, all three coordinate selectors, unequal masses, negative coordinates, decimal rounding boundaries, maximum particle count, and malformed inputs. [`benchmarks/center_of_mass_oracle.py`](../../center_of_mass_oracle.py) computes expected results independently with Python's `round`.

Build a port with the shared ABI recipe:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm center_of_mass --language rust
```

Record the workload with the build manifest:

```sh
python3 benchmarks/run_i64_array_float64.py \
  --build-manifest build/i64_array_float64/c/center_of_mass/rust/build.json
```

Verify the registered ports with:

```sh
python3 benchmarks/verify_center_of_mass.py --languages rust
```

## Implementations

| Language | Source |
|---|---|
| C | [`c/c/center_of_mass.c`](../../../c/c/center_of_mass.c) |
| C3 | [`c3/c/center_of_mass.c3`](../../../c3/c/center_of_mass.c3) |
| C++ | [`cpp/c/center_of_mass.cpp`](../../../cpp/c/center_of_mass.cpp) |
| Elisa | [`elisa/c/center_of_mass.elisa`](../../../elisa/c/center_of_mass.elisa) |
| Nim | [`nim/c/center_of_mass.nim`](../../../nim/c/center_of_mass.nim) |
| Odin | [`odin/c/center_of_mass.odin`](../../../odin/c/center_of_mass.odin) |
| Rust | [`rust/c/center_of_mass.rs`](../../../rust/c/center_of_mass.rs) |
| V | [`v/c/center_of_mass.v`](../../../v/c/center_of_mass.v) |
| Zig | [`zig/c/center_of_mass.zig`](../../../zig/c/center_of_mass.zig) |

## Pinned source

- [TheAlgorithms/Python `center_of_mass.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/center_of_mass.py)
