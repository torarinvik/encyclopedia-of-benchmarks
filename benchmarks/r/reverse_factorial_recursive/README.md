# Reverse factorial by recursive division

Given a positive integer, return its factorial root `k` when the input is exactly `k!`; otherwise return `-1`. This benchmark follows the pinned Python `reverse_factorial_recursive` with its default starting divisor of 1.

## Contract

- Input is a signed 64-bit integer in `[1, 2^63 - 1]`.
- Starting with divisor 1, recursively divide the value by divisors 1, 2, 3, and so on. If a division has a remainder, return `-1`. If the reduced value reaches 1, return the previous divisor (`current_divisor - 1`), except that initial input 1 returns 1 explicitly.
- The input `1` maps to `1` (`1!`); the source deliberately does not return 0 for `0!`.
- The pinned Python source raises `ValueError` for nonpositive input. The benchmark maps zero and negative inputs to `-1`, which is also the source result for positive nonfactorial inputs.
- The signed-i64 domain bounds the successful recursion to at most 20 divisions: `20!` fits, while `21!` does not. Time and auxiliary call-stack space are `O(k)` for a factorial root `k` and bounded by the domain.

## Source and related algorithms

The pinned [Python `reverse_factorial_recursive.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/reverse_factorial_recursive.py) performs the repeated divisions recursively and returns the factorial root, or `-1` when the value is not a factorial. This differs from the `factorial` benchmark, which computes `k!` from `k`, and `check_factorial`, which returns a membership result rather than the root.

## Workload and build

[`workload.json`](workload.json) covers the special input 1, several factorial roots, nonfactorials, the largest supported factorial, the signed-i64 boundary, and invalid nonpositive inputs. All nine ports use the shared `scalar` ABI.

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm reverse_factorial_recursive --language rust
python3 benchmarks/run_scalar.py --build-manifest build/scalar/r/reverse_factorial_recursive/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/r/reverse_factorial_recursive.c`](../../../c/r/reverse_factorial_recursive.c) |
| C3 | [`c3/r/reverse_factorial_recursive.c3`](../../../c3/r/reverse_factorial_recursive.c3) |
| C++ | [`cpp/r/reverse_factorial_recursive.cpp`](../../../cpp/r/reverse_factorial_recursive.cpp) |
| Elisa | [`elisa/r/reverse_factorial_recursive.elisa`](../../../elisa/r/reverse_factorial_recursive.elisa) |
| Nim | [`nim/r/reverse_factorial_recursive.nim`](../../../nim/r/reverse_factorial_recursive.nim) |
| Odin | [`odin/r/reverse_factorial_recursive.odin`](../../../odin/r/reverse_factorial_recursive.odin) |
| Rust | [`rust/r/reverse_factorial_recursive.rs`](../../../rust/r/reverse_factorial_recursive.rs) |
| V | [`v/r/reverse_factorial_recursive.v`](../../../v/r/reverse_factorial_recursive.v) |
| Zig | [`zig/r/reverse_factorial_recursive.zig`](../../../zig/r/reverse_factorial_recursive.zig) |
