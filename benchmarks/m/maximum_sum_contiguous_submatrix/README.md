# Maximum-sum contiguous submatrix

This benchmark finds the highest sum among all nonempty, axis-aligned
contiguous rectangles in a bounded integer matrix. It is the two-dimensional
maximum-subarray problem; it differs from [`maximum_subarray`](../maximum_subarray/README.md),
which searches one-dimensional intervals, and from [`submatrix`](../../s/submatrix/README.md),
which only copies a caller-selected region.

## Bounded profile

The `maximum_sum_contiguous_submatrix` function uses the
`i64_array_bytes_output` ABI. Input is `[rows, columns, cells...]` in row-major
order, with each dimension in `1..=8`, exact length `2 + rows*columns`, and
cell values in `[-1000,1000]`. Output is the signed 64-bit maximum rectangle
sum in little-endian form. A valid matrix may have an all-negative maximum;
the result therefore travels as an eight-byte payload. Invalid input returns
`-1`; a null output pointer or capacity below eight returns `-2`. Errors do
not write output. Fixed workspace is at most 1,024 bytes.

For each top row, the algorithm extends the bottom row and incrementally
compresses the enclosed band into column sums. A one-dimensional nonempty
Kadane scan finds the best contiguous column interval for every band. It runs
in `O(rows^2 * columns)` time and `O(columns)` auxiliary space. The maximum
absolute sum is 64,000, well within signed 64-bit arithmetic.

[`primary_oracle.py`](primary_oracle.py) uses row compression and Kadane's
algorithm. [`independent_oracle.py`](independent_oracle.py) enumerates every
rectangle and sums its cells directly. [`workload.json`](workload.json)
contains fixtures and boundary cases; `INVENTORY.md` lists the ten ports.

The Codewars [Classic Algorithm Exercises collection](https://www.codewars.com/collections/classic-algorithm-exercises)
was used only to discover the algorithm title. The method description is
cross-checked against the ETH Zürich [VerifyThis 2017 two-dimensional
maximum-sum submatrix challenge](https://ethz.ch/content/dam/ethz/special-interest/infk/chair-program-method/pm/documents/Verify%20This/challenge2.pdf).
No task statement, examples, tests, or solution code were reused.
