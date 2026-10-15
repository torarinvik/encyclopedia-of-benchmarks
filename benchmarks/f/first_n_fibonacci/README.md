# First n Fibonacci values

Emit the first `n` terms of the zero-indexed Fibonacci sequence as decimal values in ascending sequence order. This preserves the list result used by the pinned R, PHP, Nim, C#, and MATLAB sources; it is distinct from benchmarks that return only one indexed term.

## Contract

- Input is a one-element signed 64-bit array containing a term count from 3 through 79. The lower bound keeps the R source's `3:n` loop in its intended ascending range.
- The output is `F(0)` through `F(n-1)`, where `F(0)=0`, `F(1)=1`, and each later term is the sum of the preceding two.
- Each nonnegative value is encoded in decimal ASCII and followed by a NUL byte. The return value is the output byte count; invalid input returns `-1`, and insufficient output capacity returns `-2`.
- The upper bound ends at `F(78)`, which remains exact in the R source's binary64 vector and fits signed 64-bit output.

## Workload

[`workload.json`](workload.json) covers the first three and ten terms, a representative 32-term prefix, the largest exact prefix, and counts outside the normalized domain.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/first_n_fibonacci.c`](../../../c/f/first_n_fibonacci.c) |
| C3 | [`c3/f/first_n_fibonacci.c3`](../../../c3/f/first_n_fibonacci.c3) |
| C++ | [`cpp/f/first_n_fibonacci.cpp`](../../../cpp/f/first_n_fibonacci.cpp) |
| Elisa | [`elisa/f/first_n_fibonacci.elisa`](../../../elisa/f/first_n_fibonacci.elisa) |
| Nim | [`nim/f/first_n_fibonacci.nim`](../../../nim/f/first_n_fibonacci.nim) |
| Odin | [`odin/f/first_n_fibonacci.odin`](../../../odin/f/first_n_fibonacci.odin) |
| Rust | [`rust/f/first_n_fibonacci.rs`](../../../rust/f/first_n_fibonacci.rs) |
| V | [`v/f/first_n_fibonacci.v`](../../../v/f/first_n_fibonacci.v) |
| Zig | [`zig/f/first_n_fibonacci.zig`](../../../zig/f/first_n_fibonacci.zig) |

## Pinned list-output sources

- [TheAlgorithms R `first_n_fibonacci.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/mathematics/first_n_fibonacci.r)
- [TheAlgorithms PHP `Fibonacci2.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Maths/Fibonacci2.php)
- [TheAlgorithms Nim `fibonacci_numbers.nim`](https://github.com/TheAlgorithms/Nim/blob/63eec16614b46c91078653e8d3c049fe99ad36b3/dynamic_programming/fibonacci_numbers.nim) (`fibonacciSeqIterative`, `fibonacciSeqClosure`)
- [TheAlgorithms C# `FibonacciSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/FibonacciSequence.cs)
- [TheAlgorithms MATLAB `fibonacci_sequence.m`](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/maths/fibonacci_sequence.m)
