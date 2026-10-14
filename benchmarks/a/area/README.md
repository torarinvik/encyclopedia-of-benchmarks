# Shape area and surface area

This benchmark batches 22 plane-area and solid-surface-area formulas found across TheAlgorithms' files named `area`. Formula selection is explicit, so every implementation receives the same dimensions and produces the same fixed-point result without architecture-specific math instructions.

## Contract

Input is `[operation_count, operation_0, a_0, b_0, c_0, ...]`, with 0 through 256 operations and exactly four values per operation. Each operation has an opcode from this table; dimensions are integers from 0 through 1,000, and unused dimension slots must be zero.

| Opcode | Formula | `a`, `b`, `c` |
| ---: | --- | --- |
| 0 | Square area | side |
| 1 | Rectangle area | width, height |
| 2 | Triangle area from base and height | base, height |
| 3 | Circle area | radius |
| 4 | Parallelogram area | base, height |
| 5 | Trapezium (trapezoid) area | parallel sides, height |
| 6 | Triangle area by Heron's formula | three side lengths |
| 7 | Ellipse area | two semiaxes |
| 8 | Rhombus area | two diagonals |
| 9 | Cube total surface area | side |
| 10 | Cuboid total surface area | length, width, height |
| 11 | Sphere surface area | radius |
| 12 | Hemisphere total surface area | radius |
| 13 | Cylinder total surface area | radius, height |
| 14 | Cylinder lateral surface area | radius, height |
| 15 | Cone total surface area | radius, height |
| 16 | Cone lateral surface area | radius, height |
| 17 | Square-pyramid total surface area | base side, slant height |
| 18 | Conical-frustum total surface area | lower radius, upper radius, height |
| 19 | Torus surface area | major radius, tube radius |
| 20 | Regular-polygon area | side count (3–32), side length |
| 21 | Regular-prism total surface area | side count (3–32), side length, height |

Each operation produces area in milli-square-units, rounded down. The circle constant is exactly `3.141592654` for this contract; torus uses `9.869604401` as its fixed π-squared constant. Regular polygons use a shared table of `floor(1,000,000,000 * side_count * cot(π / side_count) / 4)` coefficients for side counts 3 through 32, avoiding runtime trigonometry. Square roots are integer square roots of milliscaled radicands, so the slant lengths and Heron results are deterministic across languages. Heron's formula accepts degenerate triangles and rejects side lengths that violate the triangle inequality. An empty batch returns zero. Malformed lengths, opcodes, dimensions, unused fields, and invalid triangles return `-1`.

The scalar result is the weighted sum `(operation_index + 1) * (area_milli + 1,000,000,007)`. This makes a whole batch observable through the shared signed 64-bit array/scalar ABI. Bounds keep every intermediate and checksum within signed 64-bit range.

## Workload and verification

[`workload.json`](workload.json) includes every formula, a multi-shape batch, degenerate and boundary triangles, maximum dimensions, and malformed inputs. [`verify_area.py`](../../verify_area.py) checks all formulas against an independent Python integer oracle, with small-domain exhaustive inputs, deterministic random batches, malformed records, and a maximum-size valid batch.

## Reviewed TheAlgorithms sources

- [C++ `area.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/area.cpp) and [the additional C++ repository copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/area.cpp) provide square, rectangle, triangle, circle, parallelogram, cube, sphere, cylinder, and hemisphere formulas.
- [Java `Area.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/Area.java), [JavaScript `Area.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/Area.js), [Julia `area.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/area.jl), [Kotlin `Area.kt`](https://github.com/TheAlgorithms/Kotlin/blob/b913c1d85c972fd1e679c5d832d6458b21be8fb0/src/main/kotlin/math/Area.kt), [Python `area.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/area.py), and [Solidity `Area.sol`](https://github.com/TheAlgorithms/Solidity/blob/08cba51fb38e276062b0c9791d7e0ee494ffa903/src/Maths/Area.sol) contribute overlapping plane and surface-area formulas, including Heron, ellipse, rhombus, cone, frustum, and torus variants.

Generic polygon shoelace area is benchmarked separately as [`area_of_polygon`](../area_of_polygon/README.md). Callback-based trapezoidal integration is also outside this shape-formula contract.

## Implementations

All nine portable implementations use the shared `i64_array_scalar` ABI and reside in each language's `a` folder.
