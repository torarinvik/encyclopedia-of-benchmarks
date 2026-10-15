# Number of Laser Beams

Each security device in one nonempty row connects to every device in the next nonempty row. Empty rows do not break that connection. The implementation counts devices in each row and adds the product for each consecutive pair of nonempty rows, matching the pinned C LeetCode 2125 algorithm.

## Contract

- Pack the bank as `[row_count, column_count, ASCII_cell_values...]`, in row-major order. ASCII `'0'` and `'1'` are 48 and 49.
- The bank contains 1 through 64 rows and 1 through 64 columns. Every row has the same width.
- Invalid dimensions, lengths, or cell values return `-1`.
- The input is read only. The result is the total number of device-to-device beams.
- Each implementation scans the input once and carries only the preceding nonempty row's device count. Time is O(rows × columns); auxiliary space is O(1).

## Workload and verification

[`workload.json`](workload.json) includes all-zero banks, gaps of empty rows, varied device counts, and a 64 × 64 bank. [`benchmarks/verify_number_of_laser_beams.py`](../../verify_number_of_laser_beams.py) checks all nine implementations against an independent grid oracle, including exhaustive small banks, deterministic random grids, and malformed inputs.

## Upstream source

- [TheAlgorithms/C LeetCode 2125](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/2125.c)
