# Perfect square

This benchmark returns whether an integer is a perfect square. The reviewed sources include floating-point square-root checks, integer-square-root functions, and integer binary search. The shared contract uses an exact binary search over the full signed 64-bit input range. It compares `middle` with `number / middle`, then checks the remainder when the quotient equals `middle`, so neither floating-point rounding nor a potentially overflowing `middle * middle` determines the answer.

## Contract

- Input is any signed 64-bit integer.
- Negative inputs return `0`; zero and one return `1`.
- Nonnegative input returns `1` exactly when it is a square of an integer; otherwise it returns `0`.
- Implementations use portable integer division and remainder, with no allocation or target-specific instructions.

## Workload and verification

[`workload.json`](workload.json) includes negative values, small squares and neighbors, values around the signed 32-bit boundary, and signed 64-bit extremes. [`verify_perfect_square.py`](../../verify_perfect_square.py) checks each port against Python's independent `math.isqrt` oracle, exhaustive small values, square neighbors, and deterministic full-range inputs.

## Reviewed TheAlgorithms sources

- [Rust `perfect_square.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/perfect_square.rs) — floating-point and integer binary-search variants.
- [Java `PerfectSquare.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/PerfectSquare.java) — integer input with a floating-point square root.
- [Julia `perfect_square.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/perfect_square.jl) — integer square root.

The other reviewed filename candidates include JavaScript, PHP, Python, R, Solidity, and TypeScript implementations. Their supported numeric ranges differ; the local contract standardizes them on signed 64-bit integers.
