# A-law PCM encoding

This benchmark encodes one signed 16-bit linear PCM sample into its 8-bit A-law codeword. It preserves the pinned C source's sign handling, segment search, quantization nibble, and alternating-bit mask.

## Contract

- Input is one signed integer in `[-32768, 32767]`.
- The result is the encoded octet represented as an integer in `[0, 255]`.
- Values outside the signed 16-bit PCM range return `-1`.

The reference C implementation also has a decoder and a small self-test; this benchmark measures its `encode` operation for one sample per call. The reference sample table is included in the workload.

## Workload

[`workload.json`](workload.json) covers positive and negative samples, silence, quantization boundaries, the signed extrema, and out-of-domain values.

## Reviewed source

- [Pinned C `audio/alaw.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/audio/alaw.c) implements the 16-bit PCM to 8-bit A-law encoder and decoder.

## Implementations

The nine portable implementations use the existing signed-64-bit scalar ABI. Each source is under the `a` folder for its language.
