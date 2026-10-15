# Lucas number by direct recursion

Compute the zero-based Lucas number with the direct recursive recurrence L(0)=2, L(1)=1, and L(n)=L(n-1)+L(n-2). This benchmark preserves the exponential-time recursion present in the pinned Java, Python, Rust, and Solidity sources.

## Contract

- Input is a signed 64-bit zero-based index from 0 through 25.
- Return the exact Lucas number at that index.
- Negative indices and indices above 25 return -1.

The index bound keeps the intentionally un-memoized recurrence practical. This benchmark shares its mathematical result with the [iterative Lucas benchmark](../lucas_series/README.md), but records the recursive implementation strategy separately.

## Workload and verification

The workload covers the initial terms, larger reference terms, both sides of the index bound, and signed 64-bit input boundaries. [`verify_scalar.py`](../../verify_scalar.py) checks all nine implementations against a linear-time independent oracle.

## Reviewed TheAlgorithms sources

The pinned Java `LucasSeries`, Python `recursive_lucas_number`, Rust `recursive_lucas_number`, and Solidity `lucasRecursiveTerm` use direct recursion. Java’s method is one-based; this contract normalizes all ports to zero-based indexing.

## Implementations

All nine portable implementations use the shared signed 64-bit scalar ABI.
