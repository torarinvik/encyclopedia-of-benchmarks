# Binary Multiplication

Multiply two nonnegative integers using repeated shift-and-add, running in time proportional to the number of bits in the multiplier.

## Contract

- Inputs `a` and `b` are unsigned integers from `0` through `1,000,000,000`.
- Return `a * b` as a signed 64-bit integer. The largest result is `10^18`, which fits in signed 64-bit; the intermediate doubled multiplicand also remains in range.
- The implementation uses shifts, bit tests, and addition instead of a multiplication instruction or architecture-specific intrinsics.

## Source

The pinned [TheAlgorithms/Python file](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/binary_multiplication.py) defines `binary_multiply` using this shift-and-add loop and also includes a separate modular multiplication helper. This benchmark covers the non-modular `binary_multiply` function under the catalog's `binary_multiplication` symbol.

Build and record with the shared two-input scalar ABI:

```sh
python3 benchmarks/build_abi.py --family binary_scalar --algorithm binary_multiplication --language rust
python3 benchmarks/run_binary_scalar.py --build-manifest build/binary_scalar/b/binary_multiplication/rust/build.json
```
