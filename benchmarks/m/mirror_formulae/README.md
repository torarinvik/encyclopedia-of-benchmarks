# Mirror formulae

## Contract

This package follows the three rearrangements in TheAlgorithms/Python
[mirror_formulae.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/mirror_formulae.py)
at commit e1a2a8b016001309a73d5fec4818c35cca139795. The float64_triple
inputs are [distance_a, distance_b, operation_code].

- Code 0 calls the focal-length rearrangement with object distance, then image distance.
- Code 1 calls the object-distance rearrangement with focal length, then image distance.
- Code 2 calls the image-distance rearrangement with focal length, then object distance.

Both distances must be finite, nonzero, and have absolute value in [1e-6, 1e6], following the source sign convention. The operation code must be exactly 0, 1, or 2. The ports preserve the source reciprocal-expression order. A zero input, an invalid code, or a zero denominator returns -1e300; the source raises on zero inputs and division by a singular denominator, and the sentinel makes those cases representable in this scalar ABI.

The result is compared with absolute and relative tolerance 1e-12. The workload covers all three operations, the source examples, signed inputs, bounds, invalid codes, zero inputs, and each singular denominator.

## Implementations

The nine ports are in c/m/mirror_formulae.c, c3/m/mirror_formulae.c3,
cpp/m/mirror_formulae.cpp, elisa/m/mirror_formulae.elisa,
nim/m/mirror_formulae.nim, odin/m/mirror_formulae.odin,
rust/m/mirror_formulae.rs, v/m/mirror_formulae.v, and
zig/m/mirror_formulae.zig. The workload uses the shared float64_triple
ABI and is run by benchmarks/run_float64_triple.py.
