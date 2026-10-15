# Square root by binary search

This benchmark returns the floor of the square root of a signed 64-bit integer using binary search.

## Contract

- Inputs from 0 through `INT64_MAX` return `floor(sqrt(input))`.
- Negative inputs return `-1`.
- The comparison uses `middle <= input / middle`, so the algorithm never multiplies two potentially large integers.

The Java source uses integer division to avoid square overflow. The JavaScript `SquareRootLogarithmic` source also searches for the integer floor, using squared midpoints; its normalized filename is recorded as an alias of this benchmark. All nine ports use the division comparison so they support the complete signed 64-bit nonnegative range.

## Workload and recording

`workload.json` covers zero, unit values, exact squares, values immediately around squares, negative input, and the signed 64-bit maximum. Build with the `scalar` ABI family and use `benchmarks/run_scalar.py` to record measurements.

```sh
python3 benchmarks/build_scalar.py --algorithm square_root_binary_search --language rust
```

## Reviewed sources

- [Java `SquareRootBinarySearch.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/searches/SquareRootBinarySearch.java)
- [JavaScript `SquareRootLogarithmic.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/SquareRootLogarithmic.js) is reviewed as a filename alias.
