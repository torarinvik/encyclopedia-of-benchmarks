# Minimum number of perfect squares

Despite its filename, this source solves the minimum square summands problem: find the fewest positive perfect squares whose sum equals the input.

## Contract

- Inputs from 0 through `INT32_MAX` are supported; other signed 64-bit inputs return `-1`.
- Zero returns zero. Positive perfect squares return one.
- Otherwise, search for a two-square decomposition, then use Legendre's three-square theorem after removing factors of four. Values congruent to seven modulo eight require four squares; other remaining values require three.
- The binary search and two-square scan use integer comparisons and avoid machine-specific instructions.

The pinned Java implementation uses `Math.sqrt` to recognize squares and returns one for zero. The benchmark corrects the zero case to the mathematical minimum of zero and uses integer arithmetic for portable, exact checks throughout its supported domain.

## Workload and recording

`workload.json` covers zero, one through four square summands, a factor-of-four reduction, the source's maximum input, and invalid bounds. Build with the `scalar` ABI family and record with `benchmarks/run_scalar.py`.

```sh
python3 benchmarks/build_scalar.py --algorithm sum_of_squares --language rust
```

## Reviewed source

- [Java `SumOfSquares.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/SumOfSquares.java)
