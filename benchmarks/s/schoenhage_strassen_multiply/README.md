# Schönhage–Strassen integer multiplication

Multiply two positive, fixed-width integers represented as little-endian
binary limbs. The ports use NyaanNyaan's radix-2 Schönhage–Strassen
negacyclic/cyclic transform structure over exact signed 64-bit coefficients,
then carry the convolution coefficients in base 2. The independent oracle
uses Python's arbitrary-precision integer multiplication.

## Contract

The exported `schoenhage_strassen_multiply` function uses the
`i64_array_bytes_output` ABI. Input is `[513, a[0..512], b[0..512]]`. Each
limb is a bit in `0..1`, bits are least-significant first, and each operand's
top bit must be `1`. This gives two positive 513-bit operands; the product
is returned in exactly 129 bytes. The pinned algorithm pads the 1025-term
convolution to 2048 terms: the outer exponent is 11, which recursively
transforms exponent 6 before reaching the exponent-4 naive base case. The
bounded 64-bit coefficient domain keeps every exact transform intermediate
within signed 64-bit range.

Success writes the product as a fixed-width, big-endian 129-byte integer.
Invalid input returns `-1`. Null output or capacity below 129 returns `-2`,
without writing any bytes. Both operands are at least 512 bits, so the product
always needs all 129 bytes.

[`workload.json`](workload.json) contains sparse, dense, and patterned operand
pairs, plus malformed-input, null-output, and short-capacity cases. The
independent [oracle](../../schoenhage_strassen_multiply_oracle.py) converts
the packed bits to Python integers and multiplies them directly.

## Pinned source and license

The transform schedule follows NyaanNyaan's
[`ntt/schoenhage-strassen-radix2.hpp`](https://github.com/NyaanNyaan/library/blob/b3981adc80a800b2584980b01821324ea6c77183/ntt/schoenhage-strassen-radix2.hpp)
at commit `b3981adc80a800b2584980b01821324ea6c77183`. The repository's
[`LICENSE`](https://github.com/NyaanNyaan/library/blob/b3981adc80a800b2584980b01821324ea6c77183/LICENSE)
is CC0 1.0 Universal; its complete text is bundled in [`LICENSE.txt`](LICENSE.txt).
These language ports are fresh bounded implementations of the transform
schedule.

## Ports

| Language | Port |
|---|---|
| C | [`c/s/schoenhage_strassen_multiply.c`](../../../c/s/schoenhage_strassen_multiply.c) |
| C3 | [`c3/s/schoenhage_strassen_multiply.c3`](../../../c3/s/schoenhage_strassen_multiply.c3) |
| C++ | [`cpp/s/schoenhage_strassen_multiply.cpp`](../../../cpp/s/schoenhage_strassen_multiply.cpp) |
| Elisa | [`elisa/s/schoenhage_strassen_multiply.elisa`](../../../elisa/s/schoenhage_strassen_multiply.elisa) |
| Nim | [`nim/s/schoenhage_strassen_multiply.nim`](../../../nim/s/schoenhage_strassen_multiply.nim) |
| Odin | [`odin/s/schoenhage_strassen_multiply.odin`](../../../odin/s/schoenhage_strassen_multiply.odin) |
| Rust | [`rust/s/schoenhage_strassen_multiply.rs`](../../../rust/s/schoenhage_strassen_multiply.rs) |
| V | [`v/s/schoenhage_strassen_multiply.v`](../../../v/s/schoenhage_strassen_multiply.v) |
| Zig | [`zig/s/schoenhage_strassen_multiply.zig`](../../../zig/s/schoenhage_strassen_multiply.zig) |
