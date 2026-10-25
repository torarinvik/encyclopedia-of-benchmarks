# FreeBench pcompress2

This bounded package preserves the compression core of FreeBench's `pcompress2`: sort all cyclic byte rotations into a Burrows-Wheeler last column, packetize that column with the source's run-length scheme, then encode the packets with its adaptive 16-bit arithmetic model. It returns a source-shaped compressed record rather than timing or printing a full file. The launcher repetition and file I/O are outside the profile.

## Contract

- Input is `[length, byte_0, ..., byte_(length-1)]`; length is 1 through 32 and each byte is 0 through 255.
- Equal cyclic rotations are ordered by their starting offset for portable deterministic output.
- The RLE stage keeps the source's repeated-run and unique-run packet rules, with the one-past-end lookahead treated as end-of-run. This explicitly defines the source's otherwise out-of-bounds final-byte comparison.
- Output is four-byte little-endian original length, four-byte little-endian BWT primary row, then the adaptive arithmetic bitstream. The output byte count is returned. Invalid input returns `-1`; a null or short output buffer returns `-2` without writes.
- Ports use the `i64_array_bytes_output` ABI. The independent oracle computes bounded cases for verifier corpus generation.

[`workload.json`](workload.json) includes a hand-derived one-byte record and contract edge cases; [`pcompress2_oracle.py`](../../pcompress2_oracle.py) computes expected records for other bounded byte sequences.

The pinned launcher compresses a file four times and then decompresses it. This profile performs one compression pass and exposes its complete compressed record, so BWT, RLE, adaptive-model updates, renormalization, and bit packing all affect the observable output.

## Provenance and rights

Source: [`FreeBench/pcompress2`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/FreeBench/pcompress2), pinned at commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The upstream headers identify pCompress/pUnCompress as part of FreeBench v1, intended only as a benchmark, and name Peter Rundberg (April 2001). `arithmetic.c` attributes its adaptive arithmetic-coding source to the 1987 CACM article by Witten, Neal, and Cleary. The pinned [`info.sh` launcher](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/FreeBench/pcompress2/info.sh) performs four compression passes followed by decompression. No explicit license grant was found in the pinned directory or repository root. These ports are clean-room implementations of the documented bounded behavior; no upstream implementation text was copied. This package does not claim an upstream license grant.
