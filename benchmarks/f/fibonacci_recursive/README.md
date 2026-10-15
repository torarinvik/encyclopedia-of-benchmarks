# Recursive Fibonacci

This benchmark preserves the naive recursive execution strategy used by the pinned Java, JavaScript, Dart, Zig, and Nim implementations. It complements [`fibonacci`](../fibonacci/README.md), which uses an iterative recurrence in the local ports.

## Contract

- Accept an index `n` from 0 through 30 and return `F(n)`, with `F(0)=0`, `F(1)=1`, and `F(n)=F(n-1)+F(n-2)`.
- Indices outside the bounded domain return `-1`. The upper bound keeps the exponential recursion workload practical and all results within signed 32-bit range. The Dart source uses a one-based recurrence and is mapped only for positive indices; JavaScript, Java, Zig, and Nim also define the zero case.
- The recursive recurrence is evaluated directly without memoization.

## Workload

[`workload.json`](workload.json) covers initial values, representative indices, the upper bound, and invalid indices. It uses one recursive call per sample to keep the exponential workload bounded.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/fibonacci_recursive.c`](../../../c/f/fibonacci_recursive.c) |
| C3 | [`c3/f/fibonacci_recursive.c3`](../../../c3/f/fibonacci_recursive.c3) |
| C++ | [`cpp/f/fibonacci_recursive.cpp`](../../../cpp/f/fibonacci_recursive.cpp) |
| Elisa | [`elisa/f/fibonacci_recursive.elisa`](../../../elisa/f/fibonacci_recursive.elisa) |
| Nim | [`nim/f/fibonacci_recursive.nim`](../../../nim/f/fibonacci_recursive.nim) |
| Odin | [`odin/f/fibonacci_recursive.odin`](../../../odin/f/fibonacci_recursive.odin) |
| Rust | [`rust/f/fibonacci_recursive.rs`](../../../rust/f/fibonacci_recursive.rs) |
| V | [`v/f/fibonacci_recursive.v`](../../../v/f/fibonacci_recursive.v) |
| Zig | [`zig/f/fibonacci_recursive.zig`](../../../zig/f/fibonacci_recursive.zig) |

## Pinned recursive sources

- [TheAlgorithms Java `FibonacciSeries.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/recursion/FibonacciSeries.java)
- [TheAlgorithms JavaScript `FibonacciNumberRecursive.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Recursive/FibonacciNumberRecursive.js)
- [TheAlgorithms Dart `fibonacci_recursion.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/maths/fibonacci_recursion.dart)
- [TheAlgorithms Zig `fibonacciRecursion.zig`](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/math/fibonacciRecursion.zig)
- [TheAlgorithms Nim `fibonacci_numbers.nim`](https://github.com/TheAlgorithms/Nim/blob/63eec16614b46c91078653e8d3c049fe99ad36b3/dynamic_programming/fibonacci_numbers.nim) (`fibonacciRecursive`)
