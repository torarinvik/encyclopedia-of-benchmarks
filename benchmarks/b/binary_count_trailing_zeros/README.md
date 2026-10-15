# Binary Count Trailing Zeros

Return the number of zero bits at the low end of a nonnegative integer's binary representation. For example, `36` is `100100₂`, so it has two trailing zero bits.

## Contract

- Inputs from `0` through `2^63 - 1` are valid. Zero returns `0`; negative inputs return `-1`.
- For positive inputs, repeatedly shift right while the low bit is zero and count the shifts. Time is O(k), where k is the number of trailing zero bits, and auxiliary space is O(1).
- The shared signed 64-bit ABI supports the range `1..2^63 - 1`; the Rust upstream function accepts `u64` and can represent one additional range of positive values.

## Reviewed sources

- [Python `binary_count_trailing_zeros.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/bit_manipulation/binary_count_trailing_zeros.py) isolates the lowest set bit and applies `log2`; it rejects zero and negative inputs.
- [Rust `binary_count_trailing_zeros.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/bit_manipulation/binary_count_trailing_zeros.rs) uses the integer's trailing-zero operation and returns zero for input zero.
- [Ruby `binary_count_trailing_zeroes.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/bit_manipulation/binary_count_trailing_zeroes.rb) scans the binary digits from the low end; its zero input returns one due to the string representation `"0"`.

The benchmark standardizes zero to result `0` and negative inputs to `-1`. All nine target-language implementations use the portable shift loop. See [workload.json](workload.json) and [verify_scalar.py](../../verify_scalar.py).
