# Big integer multiplication

Multiply two nonnegative integers represented as decimal strings. This package
follows the Rust `multiply` function in
[`src/big_integer/multiply.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/big_integer/multiply.rs)
at commit `fed66cb0c74c4a939ec5163648458a8c2b46fd4c`. It benchmarks that
grade-school decimal-string routine only; the Go `Matrix.Multiply` function
cataloged under the same filename is a separate matrix algorithm.

## Contract

The `i64_array_bytes_output` ABI packs input as
`[len_a, len_b, ascii_a..., ascii_b...]`, with each byte represented by its
integer value. The packed array must contain exactly `2 + len_a + len_b`
values. Both lengths are in `1..=32`. Each operand is canonical unsigned ASCII
decimal: it is either the single byte `0`, or starts with `1` through `9` and
continues with zero or more bytes `0` through `9`. Signs, empty operands,
leading zeroes, non-ASCII values, and other characters are invalid.

The product is exact base-10 multiplication. Success writes canonical ASCII
decimal bytes without a NUL terminator and returns the number of bytes written.
The result is at most 64 bytes. Invalid input returns `-1`; a null output
buffer or capacity smaller than the actual result returns `-2`. Error cases do
not write output. The benchmark's bounded ASCII domain avoids the Rust source's
panic path for invalid strings.

[`workload.json`](workload.json) covers the source examples, zero operands,
carry-heavy and unequal-length products, a 64-digit maximum product, malformed
operands and packed input, and output-buffer errors. The independent oracle is
[`benchmarks/big_integer_multiply_oracle.py`](../../big_integer_multiply_oracle.py).

Build and record the Rust port with:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm big_integer_multiply --language rust --with-checker
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/b/big_integer_multiply/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm big_integer_multiply --languages rust
```
