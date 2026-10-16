# Logarithmic power

This benchmark ports TheAlgorithms/JavaScript's powLogarithmic, which recursively halves the exponent and squares the partial result.

## Contract

- The i64_array_scalar input is [base, exponent] with exactly two signed 64-bit values.
- Base is in -10..=10 and exponent is in 0..=15. Negative exponents are invalid because the source recurses on floor(exponent / 2) and does not terminate for them.
- The chosen bounds keep every output within 10^15, so JavaScript Number represents each result exactly as an integer. The source's 0^0 result is 1.
- Invalid input returns INT64_MIN. The valid result range does not include that sentinel.
- The maximum parseable input length is 3 so an extra packed value reaches the ABI; the maximum valid input is 2 slots.

## Pinned source

- JavaScript [PowLogarithmic.js](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/PowLogarithmic.js)
- The source imports [IsEven.js](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/IsEven.js), whose predicate checks divisibility by two.

[workload.json](workload.json) covers zero and unit bases, even and odd exponents, negative bases, maximum bounds, malformed lengths, and out-of-domain inputs. The independent oracle is [pow_logarithmic_oracle.py](../../pow_logarithmic_oracle.py).

Build and run commands:
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm pow_logarithmic --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/p/pow_logarithmic/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms pow_logarithmic

## Ports

| Language | Source |
| --- | --- |
| C | [c/pow_logarithmic.c](../../../c/p/pow_logarithmic.c) |
| C3 | [c3/pow_logarithmic.c3](../../../c3/p/pow_logarithmic.c3) |
| C++ | [cpp/pow_logarithmic.cpp](../../../cpp/p/pow_logarithmic.cpp) |
| Elisa | [elisa/pow_logarithmic.elisa](../../../elisa/p/pow_logarithmic.elisa) |
| Nim | [nim/pow_logarithmic.nim](../../../nim/p/pow_logarithmic.nim) |
| Odin | [odin/pow_logarithmic.odin](../../../odin/p/pow_logarithmic.odin) |
| Rust | [rust/pow_logarithmic.rs](../../../rust/p/pow_logarithmic.rs) |
| V | [v/pow_logarithmic.v](../../../v/p/pow_logarithmic.v) |
| Zig | [zig/pow_logarithmic.zig](../../../zig/p/pow_logarithmic.zig) |
