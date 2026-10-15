# Count negative numbers in a sorted matrix

Counts negative entries in a rectangular matrix whose rows and columns are both sorted in nonincreasing order.

## Contract

- Uses the array scalar ABI: `int64_t count_negative_numbers_in_sorted_matrix(const int64_t *input, size_t length)`.
- The packed array is `[rows, columns, row-major cells...]`. Rows and columns must each be in `[1, 512]`, and the matrix must contain at most 512 cells. The packed length must equal `2 + rows * columns`; malformed shapes return `-1`.
- Cell values are signed 64-bit integers. The caller must provide rows and columns sorted in nonincreasing order.
- Returns the number of cells strictly less than zero. Zero is nonnegative.

## Source semantics

The benchmark follows pinned [TheAlgorithms Python `count_negative_numbers_in_sorted_matrix.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/matrix/count_negative_numbers_in_sorted_matrix.py), specifically `count_negatives_binary_search`. It finds the boundary between nonnegative and negative values in each descending row with binary search. The boundary from one row is reused as the upper search bound for the next because columns are also sorted descending. The function counts nonnegative cells and subtracts that total from the matrix size. The source also includes brute-force alternatives; this benchmark preserves the binary-search variant. The source assumes a nonempty rectangular grid and sorted rows/columns, so the contract requires at least one row and column and treats ordering as a precondition.

## Workload and build

[`workload.json`](workload.json) covers the source example, rectangular matrices, all-nonnegative and all-negative cases, zeros, and malformed packed shapes. Build and record with the array scalar ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm count_negative_numbers_in_sorted_matrix --language c
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/c/count_negative_numbers_in_sorted_matrix/c/build.json
```

The nine implementations are in `c/c/count_negative_numbers_in_sorted_matrix.c`, `c3/c/count_negative_numbers_in_sorted_matrix.c3`, `cpp/c/count_negative_numbers_in_sorted_matrix.cpp`, `elisa/c/count_negative_numbers_in_sorted_matrix.elisa`, `nim/c/count_negative_numbers_in_sorted_matrix.nim`, `odin/c/count_negative_numbers_in_sorted_matrix.odin`, `rust/c/count_negative_numbers_in_sorted_matrix.rs`, `v/c/count_negative_numbers_in_sorted_matrix.v`, and `zig/c/count_negative_numbers_in_sorted_matrix.zig`.
