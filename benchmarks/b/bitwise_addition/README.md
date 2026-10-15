# Bitwise addition

Adds two nonnegative integers using bitwise carry propagation, following the pinned Nim source algorithm.

## Contract

- Uses the two-input binary scalar ABI: `int64_t bitwise_addition(uint64_t first, uint64_t second)`.
- Each input is in `[0, 2^63 - 1]`, and their mathematical sum must also be at most `2^63 - 1`.
- Return the exact sum. The implementation repeatedly sets `carry = first & second`, updates `first = first ^ second`, then shifts the carry left by one into `second` until no carry remains.
- The upstream source accepts signed `int` values and demonstrates negative operands. This benchmark restricts operands to nonnegative values so every target uses unsigned shifts without signed overflow or implementation-defined behavior; within this domain the carry loop returns the same mathematical sum.
- There are no invalid cases in the workload. Values that overflow signed 64-bit output are outside the contract.

## Source semantics

The benchmark follows the pinned [TheAlgorithms Nim `bitwise_addition.nim`](https://github.com/TheAlgorithms/Nim/blob/63eec16614b46c91078653e8d3c049fe99ad36b3/maths/bitwise_addition.nim). Its `add` function repeatedly computes the shared-bit carry, combines non-carry bits with XOR, and shifts the carry left one place. The benchmark preserves those operations and restricts the source's wider signed input examples to a portable nonnegative, non-overflowing domain.

## Workload and build

[`workload.json`](workload.json) includes zero operands, the source's positive example, and increasing carry-chain lengths. Build with the shared `binary_scalar` recipe:

```sh
python3 benchmarks/build_abi.py --family binary_scalar --algorithm bitwise_addition --language rust
python3 benchmarks/run_binary_scalar.py --build-manifest build/binary_scalar/b/bitwise_addition/rust/build.json
```

The nine implementations are in `c/b/bitwise_addition.c`, `c3/b/bitwise_addition.c3`, `cpp/b/bitwise_addition.cpp`, `elisa/b/bitwise_addition.elisa`, `nim/b/bitwise_addition.nim`, `odin/b/bitwise_addition.odin`, `rust/b/bitwise_addition.rs`, `v/b/bitwise_addition.v`, and `zig/b/bitwise_addition.zig`.
