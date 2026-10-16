# Gray code

The pinned C++ source generates the reflected Gray-code sequence for a requested bit count. For positive `n`, its values are `i ^ (i >> 1)` for `i` from zero through `2^n - 1`. The C++ implementation returns an empty vector when `n <= 0`; the contract below preserves its zero boundary and bounds output size.

## Contract

- The packed input is one signed 64-bit value, the bit count `n`.
- Accept `n` from 0 through 13. For `n = 0`, return an empty sequence. For positive `n`, return all `2^n` reflected Gray-code values in order.
- Encode each value as a little-endian unsigned 32-bit integer. The return value is the number of sequence elements.
- Return `-1` for negative `n`, `n > 13`, or an input array whose length is not one.
- Return `-2` if the output buffer is too small, without writing output bytes.
- At the upper bound, the sequence contains 8,192 values and occupies 32,768 bytes.

The Python candidate `gray_code_sequence`, JavaScript candidate `gray_codes`, and Go candidate `SequenceGrayCode` compute the same sequence values for positive `n`; Python, JavaScript, and Go return `[0]` at zero, and Python raises an error for negative `n`. This package follows the pinned C++ boundary behavior.

## Workload

[`workload.json`](workload.json) includes zero, small bit counts, the upper bound, and invalid signed inputs. The byte-output oracle in `benchmarks/run_i64_array_bytes_output.py` compares the full encoded sequence.

## Upstream sources

- [TheAlgorithms/C-Plus-Plus `gray_code.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/bit_manipulation/gray_code.cpp)
- [TheAlgorithms/Python `gray_code_sequence.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/bit_manipulation/gray_code_sequence.py)
- [TheAlgorithms/JavaScript `GrayCodes.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Bit-Manipulation/GrayCodes.js)
- [TheAlgorithms/Go `rbc.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/binary/rbc.go)
