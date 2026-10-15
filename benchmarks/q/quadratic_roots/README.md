# Quadratic roots

Find the real roots of ax² + bx + c = 0 using the direct discriminant formula. Preserve the pinned source's returned root order.

## Contract

- The i64 array byte-output ABI receives exactly [a, b, c] as signed integers.
- Coefficients b and c are bounded to [-1,000,000, 1,000,000]. The leading coefficient a uses the same bound and must be nonzero.
- A negative discriminant returns zero roots; a zero discriminant returns one root; a positive discriminant returns two roots in the order (-b + sqrt(discriminant)) / (2a), then (-b - sqrt(discriminant)) / (2a).
- Each root is encoded as an IEEE-754 binary64 little-endian value. The return value is the number of roots, matching the pinned JavaScript array length.
- Malformed input, a zero leading coefficient, or an out-of-range coefficient returns -1. Insufficient output capacity returns -2 without writing a partial vector.
- These bounds keep the integer discriminant exact in binary64 and keep every supported result finite. The direct formula may lose precision for ill-conditioned equations; it is retained to match the source.
- The algorithm takes O(1) time and O(1) auxiliary space.

## Source

This follows the pinned [TheAlgorithms JavaScript QuadraticRoots.js](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/QuadraticRoots.js). The source computes b² - 4ac, returns an empty array for a negative discriminant, a single root for zero, and otherwise returns the plus-square-root formula before the minus-square-root formula. The source does not guard a = 0; the benchmark excludes that singular case and reports it as invalid input.

## Workload

[workload.json](workload.json) covers the pinned example, all root counts, irrational and fractional roots, a negative leading coefficient, coefficient boundaries, malformed input, and insufficient output capacity. Expected vectors use absolute and relative tolerance 1e-12. The workload uses comparison model i64_array_bytes_output_call and output kind float64_vector. Runtime verification remains pending.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/q/quadratic_roots.c](../../../c/q/quadratic_roots.c) |
| C3 | [c3/q/quadratic_roots.c3](../../../c3/q/quadratic_roots.c3) |
| C++ | [cpp/q/quadratic_roots.cpp](../../../cpp/q/quadratic_roots.cpp) |
| Elisa | [elisa/q/quadratic_roots.elisa](../../../elisa/q/quadratic_roots.elisa) |
| Nim | [nim/q/quadratic_roots.nim](../../../nim/q/quadratic_roots.nim) |
| Odin | [odin/q/quadratic_roots.odin](../../../odin/q/quadratic_roots.odin) |
| Rust | [rust/q/quadratic_roots.rs](../../../rust/q/quadratic_roots.rs) |
| V | [v/q/quadratic_roots.v](../../../v/q/quadratic_roots.v) |
| Zig | [zig/q/quadratic_roots.zig](../../../zig/q/quadratic_roots.zig) |

Build with the i64_array_bytes_output ABI and record with benchmarks/run_i64_array_bytes_output.py.

