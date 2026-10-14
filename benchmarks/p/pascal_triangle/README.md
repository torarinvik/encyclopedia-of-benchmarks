# Pascal triangle

This benchmark generates the first N rows of Pascal's triangle. It updates one row in place from right to left, then hashes each coefficient in row-major order. The rolling hash lets the scalar ABI check every generated coefficient without allocating or returning a matrix.

## Contract

- Input is a one-element signed 64-bit array: `[row_count]`.
- `row_count` is from 0 through 30. Zero rows produce the empty triangle and return hash zero.
- The result is a base-31 rolling hash of the coefficients modulo 1,000,000,007.
- Any other input length or row count returns `-1`.
- The limit keeps every coefficient and the Rust reference recurrence's 32-bit intermediate values in range.
- Implementations use portable integer addition and fixed-size arrays.

## Workload and verification

[`workload.json`](workload.json) records 14 cases for empty, initial, middle, and maximum-size triangles, plus invalid inputs. [`verify_pascal_triangle.py`](../../verify_pascal_triangle.py) compares the ports with exact `math.comb` coefficients over 322 oracle inputs per language and checks each workload record.

## Reviewed TheAlgorithms sources

- [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/others/pascal_triangle.cpp) — generates and prints a centered triangle.
- [Additional C++ copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/others/pascal_triangle.cpp)
- [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/PascalTriangle.java) — returns the first N rows.
- [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/PascalTriangle.js) — generates the first N rows.
- [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/matrix/pascal_triangle.py) — generates the first N rows and includes an optimized variant.
- [R](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/mathematics/pascal_triangle.r) — generates rows and also includes row and element helpers.
- [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/pascal_triangle.rs) — returns the first N rows using 32-bit values.

## Implementations

The nine portable ports use the shared `i64_array_scalar` ABI. Their source files are in the `p` folder for each language.
