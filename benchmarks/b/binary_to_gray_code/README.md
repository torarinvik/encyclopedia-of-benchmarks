# Binary integer to Gray code

This benchmark follows the primary `binary_to_gray` function in TheAlgorithms/Python's `binary_to_gray_code.py`. It converts a nonnegative integer to its binary-reflected Gray-code integer.

## Contract

- Input is one signed 64-bit integer from 0 through `INT64_MAX`.
- Return `value ^ (value >> 1)`. This matches the source formula and produces a result in the same nonnegative signed 64-bit range.
- Negative inputs return `-1`, the scalar ABI invalid-input sentinel. The Python source raises `ValueError` for negative input; the benchmark restricts the supported domain to signed 64-bit integers.
- Time and auxiliary space are `O(1)`.

## Source and related algorithms

The pinned [Python `binary_to_gray_code.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/binary_to_gray_code.py) defines integer-to-Gray conversion as `binary_number ^ (binary_number >> 1)`. Its examples include `2 -> 3`, `10 -> 15`, and `255 -> 128`. The source file also contains reverse and string conversion helpers; this benchmark covers its primary integer-to-integer operation. The separate [`binary_to_gray`](../binary_to_gray/README.md) benchmark takes a bit string and preserves its width.

## Workload and build

[`workload.json`](workload.json) covers zero, small examples, the maximum signed 64-bit input, and negative inputs. All nine ports use the shared scalar ABI.

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm binary_to_gray_code --language rust
python3 benchmarks/run_scalar.py --build-manifest build/scalar/b/binary_to_gray_code/rust/build.json
```
