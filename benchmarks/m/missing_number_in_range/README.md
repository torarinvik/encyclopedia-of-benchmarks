# Missing Number in Consecutive Range

Ports the XOR approach from the pinned TheAlgorithms/Python and TheAlgorithms/Rust implementations ([Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/bit_manipulation/missing_number.py), [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/bit_manipulation/find_missing_number.rs)). The algorithm XORs the full consecutive range with the observed values; matching values cancel, leaving the missing one. The 32-bit bit patterns are normalized arithmetically before XOR so behavior does not depend on signed representation.

The shared ABI accepts 2 to 1,024 distinct signed 32-bit values. The minimum and maximum values must be present, and the range between them must contain exactly one missing interior value. Inputs may be in any order, and ranges may cross zero. Invalid input returns -2,147,483,649, outside the valid result range. The input is not modified. Runtime and validation storage are O(n).

Run python3 benchmarks/verify_missing_number_in_range.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1 from the repository root to check all nine ports against exhaustive short permutations, signed boundaries, deterministic random inputs, and the published workload.
