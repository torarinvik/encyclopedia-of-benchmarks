# Magic square

Construct an odd-order normal magic square with the Siamese method used by the pinned Java source.

## Contract

- `scalar_call` accepts the signed 64-bit order `n`.
- Valid orders are odd integers from 1 through 31. Other inputs return `-1`.
- Start with `1` in row `n / 2`, column `n - 1`. For each later value, move one row up and one column right with wraparound when that cell is empty; otherwise move one column left with wraparound.
- The scalar result is the low 63 bits of FNV-1a-64 over this byte stream: `n` as one unsigned byte, followed by every square entry in row-major order as a signed 32-bit little-endian integer. The offset basis is `0xcbf29ce484222325` and the prime is `0x100000001b3`.

The domain keeps the pinned Java implementation's `int` cells and `n * n` loop bound in range. The order byte frames the hash input; all cell values are in `1..n²`.

## Workload and verification

[`workload.json`](workload.json) covers the minimum order, several odd orders, and invalid low, even, and high values. [`magic_square_oracle.py`](../../magic_square_oracle.py) independently constructs the square and computes the byte hash. The scalar runner compares each language implementation with these expected results.

## Reviewed source

- [Java MagicSquare.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/MagicSquare.java)

The nine portable implementations use the shared scalar ABI and live in each language's `m` folder.
