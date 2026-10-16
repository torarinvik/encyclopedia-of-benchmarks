# Gram–Schmidt orthogonalization

This benchmark follows the pinned C++ routine's row-oriented Gram–Schmidt process. It copies the first vector and, for each later vector, subtracts the sum of its projections onto every prior orthogonalized vector, in source loop order. The output vectors remain unnormalized and are serialized row-major as little-endian binary64 values.

Input is `[row_count, dimension, row-major coordinates...]`, with 1–4 rows, `row_count <= dimension <= 4`, and coordinates in thousandths from -1.000 to 1.000. To keep the source's nonzero projection denominators well-defined, each row has zero coordinates before its diagonal and a diagonal coordinate from 0.100 through 1.000. This makes the supplied rows linearly independent. The bounded contract excludes the source's interactive demo, display routine, and row-count truncation for `rows > dimension`. Invalid inputs return -1. Runtime oracle: `gram_schmidt_oracle.py`.
