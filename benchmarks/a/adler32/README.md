# Adler-32

Adler-32 computes a compact checksum of a byte sequence using two modulo-65521 sums. This benchmark adapts the pinned TheAlgorithms/Python implementation to a portable byte-array contract shared by all nine target languages.

## Contract

- The read-only input contains 0 to 100,001 bytes, each represented by an integer from 0 through 255.
- The empty sequence returns `1`.
- For each byte `x`, update `a = (a + x) mod 65521` and `b = (b + a) mod 65521`, starting with `a = 1` and `b = 0`.
- Return `(b << 16) | a` as an integer from 0 through 4,294,967,295.
- Invalid lengths, null input for a nonempty sequence, or values outside the byte range return `-1`. The input is never modified.

The source accepts text and adds each character's code point. The benchmark uses bytes so that the behavior is defined independently of language string encoding; the published source examples are ASCII and retain the same checksums.

## Workload and verification

[`workload.json`](workload.json) includes the upstream ASCII examples, empty and boundary bytes, embedded zeros, uniform and alternating data, and a 100,001-byte deterministic input. [`benchmarks/verify_adler32.py`](../../verify_adler32.py) compares the nine ports against an independent Python oracle over exhaustive short sequences, deterministic randomized sequences, invalid inputs, and every published workload record.

## Reviewed source

The pinned [TheAlgorithms/Python `adler32.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/hashes/adler32.py) implementation maintains the two sums modulo 65,521 and packs them into a 32-bit result. The byte-array contract preserves that algorithm over its byte-valued domain.

## Build

Build with the `i64_array_scalar` ABI family and record with `benchmarks/run_i64_array_scalar.py`.
