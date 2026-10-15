# Binary string to Gray code

This benchmark follows TheAlgorithms/Python's `binary_to_gray(binary)` conversion. It maps an ASCII binary string to its reflected Gray-code string while preserving the input width, including leading zeroes.

## Contract

- Input is a nonempty ASCII string of `0` and `1` characters, packed as one signed 64-bit array value per ASCII byte. The benchmark accepts 1–66 bits, matching the shared byte-output runner's small-input limit.
- The first output bit is the first input bit. Each later output bit is the XOR of the corresponding input bit and the previous input bit. This is equivalent to converting the string to an integer, XORing it with itself shifted right by one, and zero-padding to the original width.
- Return the number of output bytes. Output is ASCII `0`/`1` and always has the same width as the input.
- Empty input or a value outside ASCII `0` and `1` returns `-1`. Insufficient output capacity returns `-2` without writing output. The Python function delegates parsing to `int(binary, 2)`, which accepts additional textual forms such as surrounding whitespace; this benchmark narrows inputs to bit digits and normalizes out-of-contract values.
- Time and auxiliary space are both `O(n)` for an input of `n` bits.

## Source and related algorithms

The pinned [Python `binary_to_gray.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/binary_to_gray.py) parses a binary string, computes `value ^ (value >> 1)`, converts back to binary, and pads to the original string length. Its examples include `1101 -> 1011` and `10101010 -> 11111111`. The separately cataloged `binary_to_gray_code` source takes an integer and also implements the reverse and decimal conversion directions; it has a different input and output contract.

## Workload and build

[`workload.json`](workload.json) covers one-bit inputs, leading zeroes, the pinned examples, the 66-bit bound, empty input, and malformed characters. All nine ports use the shared `i64_array_bytes_output` ABI.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm binary_to_gray --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/b/binary_to_gray/rust/build.json
```
