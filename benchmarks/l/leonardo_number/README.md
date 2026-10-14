# Leonardo number

This benchmark computes the zero-based Leonardo number sequence. The algorithm and its source files are grouped under the `l/` letter folder.

## Contract

- `L(0) = 1` and `L(1) = 1`.
- For `n >= 2`, `L(n) = L(n - 1) + L(n - 2) + 1`.
- The input is a signed 64-bit index from `0` through `89`; invalid or out-of-range inputs return `-1`.
- Results are exact signed 64-bit integers. `L(89)` fits; `L(90)` does not.

The Java reference provides recursive and iterative variants with an `int` result. The local ports use the iterative form and extend its exact range to signed 64-bit results without relying on wrapping arithmetic.

## Workload

`workload.json` covers the initial sequence, widely spaced indices, the largest supported index, the first overflowing index, negative inputs, and signed 64-bit extremes. The verifier also checks every index from `-4` through `99` against a fast-doubling Fibonacci identity, plus boundary inputs.

## Run

Use the standard unary scalar ABI. `benchmarks/verify_scalar.py --algorithms leonardo_number` checks all nine implementations and their workload records.
