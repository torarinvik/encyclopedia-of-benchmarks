# Lucas number by iteration

Compute the zero-based Lucas number with a linear recurrence: L(0)=2, L(1)=1, and L(n)=L(n-1)+L(n-2). This benchmark uses the iterative method.

## Contract

- Input is a signed 64-bit zero-based index from 0 through 90.
- Return the exact Lucas number at that index.
- Negative indices and indices above 90 return -1.

L(90) fits in a signed 64-bit result; L(91) does not. Java’s source method numbers the same sequence from 1, so the shared zero-based contract corresponds to its argument plus one. The Ruby source uses a floating-point approximation and returns incorrect values at indices 0 and 1; the benchmark ports use exact integer recurrence.

## Workload and verification

The workload covers the initial terms, reference examples, L(90), negative indices, and the boundary above the supported range. [`verify_scalar.py`](../../verify_scalar.py) checks the implementations against an independent linear oracle in all nine languages.

## Reviewed TheAlgorithms sources

The pinned Java, JavaScript, Python, Ruby, Rust, and Solidity source files implement Lucas numbers. Python and Rust include both recursive and iterative methods; Java includes recursive and iterative methods; Solidity includes recursive and dynamic term methods. The recursive variant has its own benchmark at [lucas_series_recursive](../lucas_series_recursive/README.md).

## Implementations

All nine portable implementations use the shared signed 64-bit scalar ABI.
