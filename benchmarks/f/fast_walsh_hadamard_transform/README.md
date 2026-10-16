# Fast Walsh–Hadamard transform (XOR)

This benchmark ports the XOR transform from the pinned Python `fast_walsh_hadamard_transform.py`. It applies the standard butterfly `(x, y) -> (x+y, x-y)` in O(n log n) time. The inverse applies the same transform and divides every coefficient by `n`.

## Contract

- Input is `[inverse_flag, n, values...]`. The flag is 0 for forward or 1 for inverse. `n` is a power of two from 1 through 128, and exactly `n` values follow. Each input value is in -10,000..10,000.
- Forward mode returns the unnormalized transform. Inverse mode returns the inverse only when every transformed value is divisible by `n`; otherwise the input is invalid. Invalid packed input returns `-1` without writing output.
- Output is `n` signed 64-bit integers in little-endian byte order; the return value is `n`. Insufficient capacity returns `-2`. Bounds keep every intermediate and output value in signed 64-bit range.

[`workload.json`](workload.json) covers forward and inverse transforms, n=1, invalid sizes and directions, divisibility failure, capacity failure, value bounds, and the maximum vector length. The independent oracle uses the direct O(n²) Walsh sum.

Build and record with the `i64_array_bytes_output` ABI family:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm fast_walsh_hadamard_transform --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm fast_walsh_hadamard_transform
```

## Implementations

The nine portable ports are in `c/f/fast_walsh_hadamard_transform.c`, `c3/f/fast_walsh_hadamard_transform.c3`, `cpp/f/fast_walsh_hadamard_transform.cpp`, `elisa/f/fast_walsh_hadamard_transform.elisa`, `nim/f/fast_walsh_hadamard_transform.nim`, `odin/f/fast_walsh_hadamard_transform.odin`, `rust/f/fast_walsh_hadamard_transform.rs`, `v/f/fast_walsh_hadamard_transform.v`, and `zig/f/fast_walsh_hadamard_transform.zig`.

## Pinned source

- [TheAlgorithms/Python `fast_walsh_hadamard_transform.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/bit_manipulation/fast_walsh_hadamard_transform.py) also contains OR/AND transforms and XOR convolution; this contract focuses on its core XOR forward and inverse transform.
