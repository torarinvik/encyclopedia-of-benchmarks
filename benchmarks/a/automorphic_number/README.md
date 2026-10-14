# Automorphic number

A nonnegative integer is automorphic when its square ends with the decimal digits of the integer itself. The benchmark handles the full signed 64-bit input range without overflowing the square.

## Contract

The input is any signed 64-bit integer. Negative values return `0`. For nonnegative `n`, return `1` exactly when `n²` ends in the decimal representation of `n`; otherwise return `0`. Zero is automorphic.

Implementations find `10^digits` in unsigned 64-bit arithmetic, then calculate `n² mod 10^digits` by repeated doubling. Modular addition avoids overflowing even for 19-digit inputs. This takes O(log n) time and O(1) extra space.

## Reproduce

```sh
python3 benchmarks/build_scalar.py --algorithm automorphic_number --language c
python3 benchmarks/run_scalar.py --algorithm automorphic_number
python3 benchmarks/verify_scalar.py --algorithms automorphic_number --elisa-compiler ../Elisa-compiler/bin/elisac-stage1
```

The shared scalar verifier checks every value from -32 through 100,000, deterministic random signed 64-bit values, published large examples and their neighbors, and both signed boundaries against an arbitrary-precision oracle.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/automorphic_number.c`](../../../c/a/automorphic_number.c) |
| C3 | [`c3/a/automorphic_number.c3`](../../../c3/a/automorphic_number.c3) |
| C++ | [`cpp/a/automorphic_number.cpp`](../../../cpp/a/automorphic_number.cpp) |
| Elisa | [`elisa/a/automorphic_number.elisa`](../../../elisa/a/automorphic_number.elisa) |
| Nim | [`nim/a/automorphic_number.nim`](../../../nim/a/automorphic_number.nim) |
| Odin | [`odin/a/automorphic_number.odin`](../../../odin/a/automorphic_number.odin) |
| Rust | [`rust/a/automorphic_number.rs`](../../../rust/a/automorphic_number.rs) |
| V | [`v/a/automorphic_number.v`](../../../v/a/automorphic_number.v) |
| Zig | [`zig/a/automorphic_number.zig`](../../../zig/a/automorphic_number.zig) |

## TheAlgorithms references

- [C# `AutomorphicNumber.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Numeric/AutomorphicNumber.cs)
- [Java `AutomorphicNumber.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/AutomorphicNumber.java)
- [JavaScript `AutomorphicNumber.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/AutomorphicNumber.js)
- [Python `automorphic_number.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/special_numbers/automorphic_number.py)
