# CRC Polynomial Division

Generate a CRC codeword or check a received codeword using binary polynomial long division over GF(2). The benchmark isolates the deterministic division routine from the pinned Java simulation's random message generation, bit-error injection, and counters.

## Contract

Input is `[operation, bit_count, polynomial_bit_count, message_or_codeword_bits..., polynomial_bits...]`. Encoding accepts messages of 1 through 64 bits; checking accepts codewords of 1 through 79 bits so it can check every codeword produced by the encoder. Generator polynomial length is 2 through 16 bits. Every bit is 0 or 1, and the polynomial must have leading and constant terms equal to 1.

Operation `0` appends `polynomial_bit_count - 1` zeroes to the message, divides by the generator polynomial, then returns the original message followed by exactly `polynomial_bit_count - 1` remainder bits. Leading zeroes are retained so the encoded codeword has the fixed width required for polynomial division. Operation `1` treats the message bits as a received codeword and returns one byte: `0` for a zero remainder, `1` for a nonzero remainder. Output bytes contain the bit values 0 or 1. Invalid input returns `-1`; insufficient output capacity returns `-2` without writing.

## Source and correction

The pinned [Java `CRCAlgorithm`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/others/CRCAlgorithm.java) contains a polynomial-division routine used to append a remainder and detect a nonzero syndrome. It XORs every full-width window with the polynomial, including windows whose leading bit is 0, and trims leading zeroes without padding the final remainder back to the generator's degree. Correct GF(2) division XORs only when the current leading bit is 1, and CRC encoding appends the full-width remainder. This benchmark records and corrects both defects so generated codewords pass the corresponding check. Random message generation, bit-error injection, and simulation counters are excluded.

[`workload.json`](workload.json) covers encoding, valid and corrupted codewords, leading-zero remainders, short messages, internal polynomial zeroes, and bounds. The oracle verifier checks all nine ports.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/crc_polynomial_division.c`](../../../c/c/crc_polynomial_division.c) |
| C3 | [`c3/crc_polynomial_division.c3`](../../../c3/c/crc_polynomial_division.c3) |
| C++ | [`cpp/crc_polynomial_division.cpp`](../../../cpp/c/crc_polynomial_division.cpp) |
| Elisa | [`elisa/crc_polynomial_division.elisa`](../../../elisa/c/crc_polynomial_division.elisa) |
| Nim | [`nim/crc_polynomial_division.nim`](../../../nim/c/crc_polynomial_division.nim) |
| Odin | [`odin/crc_polynomial_division.odin`](../../../odin/c/crc_polynomial_division.odin) |
| Rust | [`rust/crc_polynomial_division.rs`](../../../rust/c/crc_polynomial_division.rs) |
| V | [`v/crc_polynomial_division.v`](../../../v/c/crc_polynomial_division.v) |
| Zig | [`zig/crc_polynomial_division.zig`](../../../zig/c/crc_polynomial_division.zig) |

Run the verifier across all nine languages with:

```sh
python3 benchmarks/verify_crc_polynomial_division.py
```
