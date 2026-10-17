# String Fibonacci

Compute a Fibonacci number with decimal-string addition so the result is not
limited to a machine integer.

## Contract

Both pinned C++ files implement the same `fib_Accurate(uint64_t)` routine. It
starts with `fibMinus1 = "1"` and `fibMinus2 = "0"`, performs `n` iterations
of manual decimal addition with carry, shifts the two strings, then writes
`fibMinus2`. This returns the standard zero-indexed Fibonacci value `F(n)`;
the interactive `main` prompt and input handling are excluded.

The `i64_array_bytes_output` ABI takes exactly one signed-i64 input, `[n]`,
with `0 <= n <= 256`. It returns the decimal ASCII digits for `F(n)` with no
newline or NUL terminator. The return value is the number of bytes written;
the largest result is 54 bytes. Invalid input framing or range returns `-1`
before output storage is checked. A null output pointer or capacity smaller
than the digit count returns `-2` without writes. The supplied output workspace
is 80 bytes. Ports preserve the source's manual decimal-add recurrence using
bounded local digit buffers. The oracle uses integer fast doubling instead.

## Workload

[`workload.json`](workload.json) covers the first terms, representative and
maximum indices, invalid frames, null output, and insufficient capacity. The
[oracle](../../string_fibonacci_oracle.py) uses integer fast doubling.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/string_fibonacci.c`](../../../c/f/string_fibonacci.c) |
| C3 | [`c3/f/string_fibonacci.c3`](../../../c3/f/string_fibonacci.c3) |
| C++ | [`cpp/f/string_fibonacci.cpp`](../../../cpp/f/string_fibonacci.cpp) |
| Elisa | [`elisa/f/string_fibonacci.elisa`](../../../elisa/f/string_fibonacci.elisa) |
| Nim | [`nim/f/string_fibonacci.nim`](../../../nim/f/string_fibonacci.nim) |
| Odin | [`odin/f/string_fibonacci.odin`](../../../odin/f/string_fibonacci.odin) |
| Rust | [`rust/f/string_fibonacci.rs`](../../../rust/f/string_fibonacci.rs) |
| V | [`v/f/string_fibonacci.v`](../../../v/f/string_fibonacci.v) |
| Zig | [`zig/f/string_fibonacci.zig`](../../../zig/f/string_fibonacci.zig) |

## Pinned sources

- TheAlgorithms/C-Plus-Plus [`string_fibonacci.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/string_fibonacci.cpp) at `fdcc29b0ac2848e9d1a8d926e171cc5b39f97759`.
- TheAlgorithms/C-Plus-Plus-1 [`string_fibonacci.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/string_fibonacci.cpp) at `0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680`.

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm string_fibonacci --language c
python3 benchmarks/run_i64_array_bytes_output.py --algorithm string_fibonacci
```
