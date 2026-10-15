# Unique Paths

This benchmark counts paths from the top-left to the bottom-right of a rectangular grid when each move goes either one cell right or one cell down.

## Contract

- Inputs are two unsigned 64-bit integers: `rows` and `columns`.
- Each dimension must be from 1 through 34. Invalid dimensions return `-1`.
- The result is `C(rows + columns - 2, rows - 1)`, computed exactly in signed 64-bit output. The largest accepted grid, 34 by 34, has 7,219,428,434,016,265,740 paths.
- Each port uses a single dynamic-programming row sized to the smaller dimension. The recurrence adds the paths from the cell above and the cell to its left.

The bounded contract keeps every result within signed 64-bit while including cases larger than Java's 32-bit result type and JavaScript's exact-integer range.

## Inspected upstream sources

- [TheAlgorithms/Java `UniquePaths.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/UniquePaths.java)
- [TheAlgorithms/JavaScript `UniquePaths.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Dynamic-Programming/UniquePaths.js)

The Java source provides one-dimensional dynamic programming with swapped dimensions and a two-dimensional variant. It uses `int` additions that throw on overflow. JavaScript updates one row of `Number` values and can lose integer precision for larger grids. The shared contract uses a bounded 64-bit result across all target languages.

## Workload and verification

[`workload.json`](workload.json) includes single-row and single-column grids, rectangular and square grids, the maximum accepted dimensions, and invalid unsigned inputs. [`benchmarks/verify_unique_paths.py`](../../verify_unique_paths.py) checks every grid with dimensions 0 through 36, unsigned 64-bit boundaries, deterministic random inputs, and each workload case against Python's arbitrary-precision `math.comb` oracle in all nine target languages.

```sh
python3 benchmarks/verify_unique_paths.py --elisa-compiler /absolute/path/to/elisac
```

Build and record with the `binary_scalar` ABI family. Source ports are in `u/` in all nine language directories.
