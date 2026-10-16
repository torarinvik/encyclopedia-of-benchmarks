# Complex number multiplication

Multiply two complex numbers supplied in the source's ASCII string format. The
benchmark follows the pinned Java
[`ComplexNumberMultiply.multiply`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/ComplexNumberMultiply.java):
parse `a+bi`, compute `(ac - bd) + (ad + bc)i`, then format the result as
`real+imaginaryi`.

## Contract

- Input is `[left_length, right_length, left_ascii..., right_ascii...]`. Each
  string is 4 to 64 ASCII bytes and the packed input contains exactly the two
  declared strings. Each string follows `-?digits+-?digitsi`; decimal leading
  zeroes are accepted.
- Parsed real and imaginary components are in `[-32767, 32767]`. This bounded
  subset keeps both source `int` products and their sum or difference in range,
  so every accepted multiplication has the Java result without overflow.
- Output is the result string encoded as ASCII bytes, with no NUL terminator.
  Negative imaginary values retain the source's `+-` spelling. The maximum
  output workspace is 24 bytes.
- Invalid packing, non-ASCII bytes, malformed strings, or out-of-range
  components return `-1`. A null or undersized output buffer returns `-2`.

[`workload.json`](workload.json) covers positive and negative components,
leading zeroes, maximum accepted values, malformed strings and packing, the
ASCII boundary, and insufficient output capacity.

Build the Rust port and record its workload with:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm complex_number_multiply --language rust --with-checker
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/c/complex_number_multiply/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm complex_number_multiply
```

Verify every port against the source-ordered oracle and workload with:

```sh
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm complex_number_multiply
```

| Language | Source |
| --- | --- |
| C | [`c/c/complex_number_multiply.c`](../../../c/c/complex_number_multiply.c) |
| C3 | [`c3/c/complex_number_multiply.c3`](../../../c3/c/complex_number_multiply.c3) |
| C++ | [`cpp/c/complex_number_multiply.cpp`](../../../cpp/c/complex_number_multiply.cpp) |
| Elisa | [`elisa/c/complex_number_multiply.elisa`](../../../elisa/c/complex_number_multiply.elisa) |
| Nim | [`nim/c/complex_number_multiply.nim`](../../../nim/c/complex_number_multiply.nim) |
| Odin | [`odin/c/complex_number_multiply.odin`](../../../odin/c/complex_number_multiply.odin) |
| Rust | [`rust/c/complex_number_multiply.rs`](../../../rust/c/complex_number_multiply.rs) |
| V | [`v/c/complex_number_multiply.v`](../../../v/c/complex_number_multiply.v) |
| Zig | [`zig/c/complex_number_multiply.zig`](../../../zig/c/complex_number_multiply.zig) |
