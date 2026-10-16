# Weight conversion

Convert values among the 23 weight units in the pinned Rust source. The
benchmark preserves its one-factor table and its operation order: multiply the
input by the source unit's kilogram factor, then divide by the destination
unit's kilogram factor. This is a separate identity from the existing
11-unit `weight_conversion` benchmark, which uses different factors and
separate source/destination charts.

## Contract

- Uses the `float64_triple` ABI with inputs `[value, from_code, to_code]`.
- `value` must be finite and in `[-1,000,000, 1,000,000]`.
- Unit codes must be exact integral binary64 values from `0` through `22`, in
  the pinned Rust enum order shown below.
- Valid inputs return `(value * from_factor) / to_factor`, using the factor
  table in the pinned source.
- Invalid values or codes return exactly `-1e300`. A valid result cannot equal
  this sentinel under the bounded input contract.

| Code | Unit | Kilograms per unit |
|---:|---|---:|
| 0 | gigatonne | `1e12` |
| 1 | megatonne | `1e9` |
| 2 | metric ton | `1000.0` |
| 3 | kilogram | `1.0` |
| 4 | gram | `1e-3` |
| 5 | milligram | `1e-6` |
| 6 | microgram | `1e-9` |
| 7 | nanogram | `1e-12` |
| 8 | picogram | `1e-15` |
| 9 | long ton | `1016.0469088` |
| 10 | short ton | `907.18474` |
| 11 | hundredweight | `50.80234544` |
| 12 | quarter | `12.70058636` |
| 13 | stone | `6.35029318` |
| 14 | pound | `0.45359237` |
| 15 | ounce | `0.028349523125` |
| 16 | dram | `0.0017718451953125` |
| 17 | grain | `0.00006479891` |
| 18 | troy pound | `0.3732417216` |
| 19 | troy ounce | `0.0311034768` |
| 20 | pennyweight | `0.00155517384` |
| 21 | carat | `0.0002` |
| 22 | atomic mass unit | `1.66053906660e-27` |

The pinned [Rust `weight.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/conversions/weight.rs)
accepts unit enums or case-insensitive string aliases and converts through
kilograms. This benchmark uses canonical unit codes while preserving its
factor values and arithmetic order.

The workload includes every source/destination pair, negative and boundary
values, source examples, fractional codes, and invalid unit codes. Results use
an output-relative tolerance of `1e-12` when the expected result is nonzero;
zero and underflow results must match exactly.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/w/weight.c](../../../c/w/weight.c) |
| C3 | [c3/w/weight.c3](../../../c3/w/weight.c3) |
| C++ | [cpp/w/weight.cpp](../../../cpp/w/weight.cpp) |
| Elisa | [elisa/w/weight.elisa](../../../elisa/w/weight.elisa) |
| Nim | [nim/w/weight.nim](../../../nim/w/weight.nim) |
| Odin | [odin/w/weight.odin](../../../odin/w/weight.odin) |
| Rust | [rust/w/weight.rs](../../../rust/w/weight.rs) |
| V | [v/w/weight.v](../../../v/w/weight.v) |
| Zig | [zig/w/weight.zig](../../../zig/w/weight.zig) |

## Build and verification

```sh
python3 benchmarks/build_abi.py --family float64_triple --algorithm weight --language rust
python3 benchmarks/run_float64_triple.py --build-manifest build/float64_triple/w/weight/rust/build.json
python3 benchmarks/verify_weight.py --languages rust
```
