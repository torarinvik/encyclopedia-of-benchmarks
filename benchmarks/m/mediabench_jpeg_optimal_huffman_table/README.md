# MediaBench IJG JPEG Optimal Huffman Table

This package isolates the source `jpeg_gen_optimal_table` frequency-to-table stage from IJG JPEG 6a. The `mediabench/jpeg/jpeg-6a` launcher invokes `cjpeg` with `-opt`, which gathers DC and AC coefficient-symbol frequencies and generates optimized Huffman tables. This profile covers one such table from a bounded sparse frequency map; it does not encode image blocks or create JPEG files.

## Contract

- Input is `[symbol_count, symbol_0, frequency_0, ...]` in signed 64-bit cells.
- `symbol_count` is 1–20. Symbols are distinct integers in `[0,255]`; frequencies are positive integers up to 1,000,000. The frame length is exactly `1 + 2*symbol_count` and at most 41 cells.
- The total real frequency is at most 20,000,000, below the source routine's `1,000,000,000` minimum-search sentinel.
- The table builder appends IJG's pseudo-symbol 256 with frequency 1. Its greedy merges choose the smallest nonzero frequencies, with larger symbol/root IDs winning ties. The result applies IJG's JPEG maximum-code-length-16 redistribution and then removes the pseudo-symbol.
- Return `17+symbol_count` and write bytes `[symbol_count, bits[1],...,bits[16], huffval...]`. `huffval` follows the source's original tree-code-size ordering and ascending symbol order within each size; length redistribution changes the counts but not the source's original `codesize` array.
- Invalid input returns `-1`. Null output or insufficient capacity returns `-2` without writing. Maximum output size is 37 bytes.

The oracle uses a tree-of-leaf-lists Huffman representation rather than the source's `others[]` branch chain. It compares the resulting code-length histogram and source-ordered symbol list. Bounded cases include single-symbol, equal-frequency ties, malformed tables, and output-capacity errors. The 20-symbol domain also allows the 16-bit length-limiting path.

## Source and rights

- Repository: [lac-dcc/Benchmarks](https://github.com/lac-dcc/Benchmarks)
- Pinned revision: `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`
- Source: [`mediabench/jpeg/jpeg-6a/jchuff.c::jpeg_gen_optimal_table`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/mediabench/jpeg/jpeg-6a/jchuff.c)
- Launcher: [`mediabench/jpeg/jpeg-6a/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/mediabench/jpeg/jpeg-6a/info.sh), `cjpeg -dct int -progressive -opt`.
- The source identifies Independent JPEG Group software and copyright © 1991–1996 Thomas G. Lane. IJG's redistribution grant and required acknowledgement are reproduced in [`LICENSE.txt`](LICENSE.txt). These ports are independently written and contain no copied source text or comments.

This software is based in part on the work of the Independent JPEG Group.

This table-construction kernel is distinct from local JPEG forward/inverse DCT, color conversion, component upsampling, baseline block decoding, generic Huffman compression, and Huffman weighted-cost packages.
