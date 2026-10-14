# Perfect cube

This benchmark determines whether an integer is the cube of an integer.

## Contract

- The input is one signed 64-bit integer in `[-1,000,000,000,000, 1,000,000,000,000]`.
- The result is `1` for a perfect cube, including zero and negative cubes, and `0` otherwise. Inputs outside the range return `-1`.
- The ports use integer binary search over root magnitudes 0 through 10,000. The bound makes every intermediate cube fit signed 64-bit arithmetic and avoids floating-point rounding.

The pinned Rust and Python implementations include a binary-search variant and agree that negative perfect cubes are valid. The Rust variant takes the signed absolute value and cubes its midpoint directly, which can overflow at the signed minimum or for large midpoints; the Python file also includes a floating-point cube-root variant. The bounded local contract uses exact integer arithmetic and gives all target languages one portable scalar comparison.

## Inspected upstream sources

- [Java — `src/main/java/com/thealgorithms/maths/PerfectCube.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/PerfectCube.java)
- [JavaScript — `Maths/PerfectCube.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/PerfectCube.js)
- [Julia — `src/math/perfect_cube.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/perfect_cube.jl)
- [Python — `maths/perfect_cube.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/perfect_cube.py)
- [Rust — `src/math/perfect_cube.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/perfect_cube.rs)
- [TypeScript — `maths/perfect_cube.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/maths/perfect_cube.ts)

## Workload and verification

`workload.json` covers signed cubes, adjacent non-cubes, zero, both range boundaries, and invalid signed inputs. The verifier uses an exact integer Newton oracle, checks every input from -2048 through 2048, checks every cube and its neighbors across the supported root range, and checks deterministic random inputs in all nine languages.

```sh
python3 benchmarks/verify_perfect_cube.py --elisa-compiler /absolute/path/to/elisac
```

Build and record with the `scalar` ABI family. Source ports are in `p/` in all nine language directories.
