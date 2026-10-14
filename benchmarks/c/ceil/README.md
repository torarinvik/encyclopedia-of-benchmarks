# Ceiling of exact rational values

This benchmark computes the mathematical ceiling of a batch of exact rational numbers. Each value is represented as a signed numerator divided by a positive denominator.

## Contract

- Input is `[value_count, numerator_0, denominator_0, ..., numerator_n-1, denominator_n-1]`.
- Value count is 0 through 256; numerators are in `[-1,000,000,000,000, 1,000,000,000,000]`; denominators are in `[1, 1,000,000]`.
- The result for each pair is the smallest integer greater than or equal to its exact quotient. The signed 64-bit scalar output is the weighted sum of the ceiling values plus a fixed positive offset. Invalid inputs return `-1`.
- This exact rational domain avoids floating-point rounding differences and stays within signed 64-bit arithmetic on all targets.

## Workload and verification

[`workload.json`](workload.json) covers positive and negative fractions, integers, zero, large numerator and denominator boundaries, batches, and malformed input. [`verify_ceil.py`](../../verify_ceil.py) checks the implementations against exact integer arithmetic over exhaustive small fractions, deterministic randomized batches, and malformed arrays.

## Reviewed TheAlgorithms sources

The eight pinned sources in C-Sharp, Java, Julia, Mojo, Python, Ruby, Rust, and Zig aim to compute the ceiling function. They differ in number domains and representations: Java preserves nonfinite values and values outside its integer conversion range; Rust casts through 32-bit integers; Zig's current generic implementation returns a positive fractional input unchanged. The shared contract uses exact rational arithmetic to provide one precise mathematical result across the benchmark languages.

- [C-Sharp](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Numeric/Ceil.cs) and [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/Ceil.java) implement ceiling with integer conversions and bounds checks.
- [Julia](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/ceil.jl), [Mojo](https://github.com/TheAlgorithms/Mojo/blob/de31759cab02892cb7ccc7767d97fc000b10fcae/maths/ceil.mojo), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/ceil.py), and [Ruby](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/maths/ceil.rb) use truncation and a fractional-part check.
- [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/ceil.rs) converts through a 32-bit integer; [Zig](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/math/ceil.zig) provides a generic numeric implementation.

## Implementations

The nine portable ports use the shared `i64_array_scalar` ABI. Their source files are in the `c` folder for each language.
