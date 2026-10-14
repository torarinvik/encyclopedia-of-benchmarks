# Binomial coefficient

This benchmark computes the exact number of ways to choose `k` items from `n`, using Pascal's triangle.

## Contract

- Inputs are two unsigned 64-bit integers, `n` and `k`.
- `n` must be at most 66; otherwise the result is `-1`. The bound keeps every result within signed 64-bit range.
- The result is `C(n, k)`. If `k > n`, the result is 0. In particular, `C(0, 0) = 1`.
- The implementation updates one fixed 67-element row in descending `k` order, so each iteration uses only the previous row and allocates no memory.

The pinned sources include Pascal-triangle and multiplicative variants. The Python source returns 1 for `(0, k)` when `k > 0` because it handles zero before the `k > n` case; the shared contract uses the standard binomial definition and returns 0 there. The Rust source uses arbitrary-precision results and assumes its loop's `n - i` remains valid. The local contract uses `C(n,k)` for the exact, bounded comparison domain.

## Inspected upstream sources

- [C-Sharp — `Algorithms/Numeric/BinomialCoefficient.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Numeric/BinomialCoefficient.cs)
- [Java — `src/main/java/com/thealgorithms/maths/BinomialCoefficient.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/BinomialCoefficient.java)
- [JavaScript — `Maths/BinomialCoefficient.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/BinomialCoefficient.js)
- [Python — `maths/binomial_coefficient.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/binomial_coefficient.py)
- [Rust — `src/math/binomial_coefficient.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/binomial_coefficient.rs)
- [TypeScript — `maths/binomial_coefficient.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/maths/binomial_coefficient.ts)

## Workload and verification

`workload.json` covers zero cases, symmetry, the center of a large row, the largest `n` that fits the signed result contract, and invalid inputs. The verifier checks every pair from 0 through 66 against Python's arbitrary-precision `math.comb`, then checks unsigned 64-bit boundaries and each workload record in all nine languages.

```sh
python3 benchmarks/verify_binomial_coefficient.py --elisa-compiler /absolute/path/to/elisac
```

Build and record with the `binary_scalar` ABI family. Source ports are in `b/` in all nine language directories.
