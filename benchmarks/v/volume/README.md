# Geometric volume formulas

This package follows the geometric formulas shared by the pinned C++, Java, JavaScript, Julia, Python, and Solidity sources. The C++ mirror in C-Plus-Plus-1 has the same formulas as the C++ source. The Rust file with the same basename converts among measurement units and is a separate algorithm; it is not included here. Python and Java also contain shape formulas outside this shared subset.

## Contract

The `i64_array_scalar` input is `[operation, a, b, c]`. All dimensions are integers from 0 through 1000. Operation 0 computes a cube (`a³`) and requires `b = c = 0`. Operation 1 computes a cuboid (`a × b × c`). Operation 2 computes a triangular prism (`a × b × c / 2`), and operation 3 computes a rectangular pyramid (`a × b × c / 3`). Operations 2 and 3 accept only inputs whose product divides evenly by the denominator, so all four operations have exact integer results across the source languages. Unsupported selectors, nonzero unused cube fields, out-of-range dimensions, fractional results, or malformed input return `-1`.

The package uses bounded signed 64-bit integer arithmetic. Its largest intermediate product is 1,000,000,000. Geometry formulas involving circles are excluded because the source files use different π constants and numeric conventions: C++ defaults to 3.14, Solidity uses fixed-point approximations with integer truncation, and the other sources use their language's π value.

## Workload and recording

[`workload.json`](workload.json) covers each operation, zero dimensions, exact and fractional divisibility, malformed selector fields, invalid dimensions, and malformed packed lengths. The shared scalar runner checks each expected result against the bounded selector formulas.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm volume --language rust
python3 benchmarks/run_i64_array_scalar.py --algorithm volume
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/v/volume.c`](../../../c/v/volume.c) |
| C3 | [`c3/v/volume.c3`](../../../c3/v/volume.c3) |
| C++ | [`cpp/v/volume.cpp`](../../../cpp/v/volume.cpp) |
| Elisa | [`elisa/v/volume.elisa`](../../../elisa/v/volume.elisa) |
| Nim | [`nim/v/volume.nim`](../../../nim/v/volume.nim) |
| Odin | [`odin/v/volume.odin`](../../../odin/v/volume.odin) |
| Rust | [`rust/v/volume.rs`](../../../rust/v/volume.rs) |
| V | [`v/v/volume.v`](../../../v/v/volume.v) |
| Zig | [`zig/v/volume.zig`](../../../zig/v/volume.zig) |

## Pinned source files

- C++ [`volume.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/volume.cpp)
- C++ mirror [`volume.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/volume.cpp)
- Java [`Volume.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/Volume.java)
- JavaScript [`Volume.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/Volume.js)
- Julia [`volume.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/volume.jl)
- Python [`volume.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/volume.py)
- Solidity [`volume.sol`](https://github.com/TheAlgorithms/Solidity/blob/08cba51fb38e276062b0c9791d7e0ee494ffa903/src/Maths/volume.sol)
- Excluded Rust unit converter [`volume.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/conversions/volume.rs)
