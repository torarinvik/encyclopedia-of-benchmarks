# Trimorphic number

A trimorphic number is a nonnegative integer whose cube ends with the number's decimal digits. This benchmark follows the pinned Python candidate and uses a suffix modulus instead of converting the cube and input to strings.

## Contract

- Input is a signed 64-bit integer in `[0, 2,000,000]`. Negative or larger values return `-1`.
- Return `1` when `n³ mod 10ᵈ = n`, where `d` is the number of decimal digits in `n`, and `0` otherwise. Zero has one decimal digit and is trimorphic.
- The input bound keeps `n³` within signed 64-bit range. The modulus is at most `10,000,000`.

The pinned [TheAlgorithms Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/special_numbers/trimorphic_number.py) defines the suffix property, accepts zero, and raises an error for negative input. The benchmark maps invalid negative inputs to `-1` and bounds the input so every language computes the cube exactly.

[`workload.json`](workload.json) covers zero, known trimorphic values, non-matches, the upper bound, and invalid inputs. Build and record with the scalar ABI:

```sh
python3 benchmarks/build_scalar.py --algorithm trimorphic_number --language c
python3 benchmarks/run_scalar.py --algorithm trimorphic_number
```

Implementations: `c/t/trimorphic_number.c`, `c3/t/trimorphic_number.c3`, `cpp/t/trimorphic_number.cpp`, `elisa/t/trimorphic_number.elisa`, `nim/t/trimorphic_number.nim`, `odin/t/trimorphic_number.odin`, `rust/t/trimorphic_number.rs`, `v/t/trimorphic_number.v`, and `zig/t/trimorphic_number.zig`.
