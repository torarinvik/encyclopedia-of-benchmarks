# Central Polygonal Numbers Sequence

Return the central polygonal number at a zero-based position `n`. The pinned C# source defines the infinite sequence as `n * (n + 1) / 2 + 1`, starting with `n = 0`, so the first values are `1, 2, 4, 7, 11, ...`.

## Contract

- Inputs from `0` through `4,294,967,295` are valid. The maximum is the greatest index whose central polygonal number fits a signed 64-bit result.
- Negative inputs and indices above that limit return `-1`.
- Ports divide the even factor before multiplication, then add one. This keeps every intermediate in signed 64-bit range, including at the maximum supported index.
- The function uses the unary signed 64-bit scalar ABI and has constant time and space complexity.

This is the central polygonal sequence, also called the Lazy Caterer's sequence. It is distinct from [`triangular_number`](../../t/triangular_number/README.md), whose value at the same index is exactly one less.

The source is the pinned [TheAlgorithms/C-Sharp `CentralPolygonalNumbersSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/CentralPolygonalNumbersSequence.cs). It lazily yields `BigInteger` values, with the index beginning at zero.

Build one port with `python3 benchmarks/build_scalar.py --algorithm central_polygonal_numbers_sequence --language LANGUAGE`. The build manifest is written to `build/scalar/c/central_polygonal_numbers_sequence/LANGUAGE/build.json`; the workload uses the standard scalar runner interface in [`benchmarks/run_scalar.py`](../../run_scalar.py).
