# Matrix addition

Add two integer matrices with matching dimensions, producing a new row-major matrix. The pinned Go source implements this as a generic `Matrix[T].Add` operation and launches one goroutine per row. This benchmark captures its elementwise result and dimension-error semantics; concurrency is an implementation detail of that Go method and is not required by the shared cross-language ABI.

Source: [TheAlgorithms/Go `math/matrix/add.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/matrix/add.go), with dimensions from [`math/matrix/matrix.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/matrix/matrix.go).

## Contract

Input is `[rows_a, columns_a, A row-major values..., rows_b, columns_b, B row-major values...]`. Each dimension is 0 through 16, with at most 256 elements per matrix. A zero-row matrix must be 0×0; a positive-row, zero-column matrix is allowed. The input length must exactly match the encoded matrices. Elements must be signed 32-bit integers.

Matching dimensions return the elementwise sum as row-major little-endian signed 32-bit values. Addition wraps modulo 2^32, matching Go's signed integer operation for `T=int32`. The function returns the element count, `-1` for dimension mismatch (the source returns an error), `-2` for malformed/out-of-domain input, and `-3` for insufficient output capacity.
