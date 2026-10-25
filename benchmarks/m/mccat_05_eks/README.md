# McCat 05-eks symmetric eigensolver

This package ports the McCat 05-eks symmetric eigensolver. It retains the source's Givens band-to-tridiagonal reduction followed by shifted symmetric QR iteration with Givens chasing. The benchmark accepts a bounded matrix directly; the source's Gaussian matrix generator, output-file wrapper, and timing harness are outside this core.

## Contract

The `i64_array_bytes_output` entry point is `mccat_05_eks`. Input is `[n, half_bandwidth, row-major matrix entries]`, where entries are signed integers representing real values divided by 1,000,000. Orders are 3 through 8. Half-bandwidth is 2 through 5 and must be smaller than the order. Values are limited to `[-1,000,000, 1,000,000]`; the matrix must be symmetric, and entries outside the declared band must be zero.

The solver follows the source's reduction schedule and shifted QR recurrence, including its `1e-10` relative deflation threshold and shift sign rule. The bounded profile caps the overall number of QR sweeps at 4,096. A successful result contains all diagonalized eigenvalues sorted by descending absolute value, with signed ascending order for equal magnitudes. Each value is rounded to the nearest 1/1,000 (ties away from zero), converted to signed i32, and emitted as a little-endian byte vector. The return value is the vector's byte count. Invalid input returns `-1`; null output or insufficient capacity returns `-2` without writes.

The workload has diagonal and single-coupling matrices with hand-solvable spectra for every supported order, plus a three-by-three quantized source-shaped Gaussian-band matrix. The independent Python oracle uses cyclic Jacobi rotations rather than the source's Givens reduction and shifted QR.

## Pinned source and notice

Source: [`McCat/05-eks`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McCat/05-eks) in `lac-dcc/Benchmarks`, commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The source files identify Mikkel Damsgaard as author and retain this distribution notice:

```text
Copyright (C) 1996 McGill University.
Copyright (C) 1996 McCAT System Group.
Copyright (C) 1996 ACAPS Benchmark Administrator
                   benadmin@acaps.cs.mcgill.ca

This program is free software; you can redistribute it and/or modify
it provided this copyright notice is maintained.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
```

The complete notice is preserved in each language port. The ports adapt the source to the explicit bounded matrix ABI and are not copies of its matrix-generation or file-output wrapper.

See [workload.json](workload.json) and the [independent oracle](../../mccat_05_eks_oracle.py).
