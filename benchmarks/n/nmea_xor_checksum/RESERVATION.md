# Reservation: NMEA payload XOR checksum

**Status:** Implemented across all ten supported languages and registered in the scalar runner/verifier. Ports remain uncompiled and unexecuted by design.

## Contract

Use the `i64_array_scalar` ABI. The input is `[length, payload byte... ]`,
where `0 <= length <= 76`; each payload value must be a 7-bit byte in
`0..=127`. The payload is the sentence content after its start delimiter and
before `*`; delimiters, hexadecimal checksum text, and line endings are not
part of the input. Return the 8-bit XOR fold, with an empty payload returning
zero. Invalid frames return `-1`.

The algorithm runs in `O(length)` time and `O(1)` auxiliary space. The 76-byte
limit follows the 82-byte maximum sentence length after accounting for a start
delimiter, `*`, two checksum digits, and CR/LF. This bounded XOR checksum is
distinct from the local `hash_xor8` routine, which adds bytes and applies
two's-complement finalization, as well as from Internet checksum, Fletcher,
Adler, and CRC packages.

## Provenance and rights

The discovery lead was Codewars's title-only catalog; protocol context is
GPSD's [NMEA Revealed, NMEA Encoding Conventions](https://gpsd.gitlab.io/gpsd/NMEA.html).
It describes the 8-bit XOR over sentence characters excluding the framing and
checksum delimiters, and gives the 82-byte sentence maximum. This package uses
that protocol description to define a clean-room core payload API. No
community problem text, code, examples, tests, or fixtures are copied.
