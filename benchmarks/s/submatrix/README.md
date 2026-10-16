# submatrix

This benchmark extracts a rectangular submatrix from a row-major matrix. The input is `[rows, cols, rowStart, colStart, numRows, numCols, cells...]`; rows and columns are bounded to 1–8 with at most 64 signed 32-bit cells. The requested region must fit inside the source. Zero output rows or columns are valid and preserve the requested shape.

The scalar result is the signed interpretation of a 64-bit FNV-1a hash over `numRows`, `numCols`, then the selected cells in row-major order. Each value contributes its eight little-endian bytes. Invalid inputs return `-1`. This hash keeps the output compatible with the scalar ABI while making the copied contents observable.

The pinned Go source allocates a fresh matrix and copies each requested cell, using goroutines for the copy. The benchmark preserves the selected rectangle and empty-shape behavior; execution is sequential because the bounded contract measures the extraction result rather than goroutine scheduling.
