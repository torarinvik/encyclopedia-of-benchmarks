# NBench Huffman compression

This package is a bounded algorithm-kernel variant of the Huffman test in NBench's BYTEmark suite, not an official benchmark run or score. It ports the complete frequency/tree construction, compression, decompression, and round-trip check from `nfinit/ansibench` commit `ef90abd09d7b7bb1f2809f896d6f67fb9724bebe`, `nbench/src/nbench1.c` (`DoHuffIteration`, `SetCompBit`, `GetCompBit`).

## Contract

Input is a signed i64 array `[text_length, byte_0, ...]`, with 1–128 payload bytes in the range 32–47. The algorithm appends an implicit NUL, matching NBench's `plaintext[arraysize - 1] = '\0'` and `arraysize`-byte frequency/encode loops. The payload plus terminator therefore has at least two symbols. Restricting payload symbols to 16 printable ASCII values keeps the upstream 30-bit path buffer safe while still exercising tree construction and bitstream encoding.

The tree has 512 entries and 256 candidate leaves. Frequencies are normalized as float32, and each merge scans nodes in ascending index order using strict `<` comparisons, preserving the source's first-minimum tie behavior. Bits are emitted in source path order, least-significant bit first within each byte. The kernel decodes the staged bitstream and verifies every payload byte plus the terminator before returning.

Output is `[bit_count:u32le, packed_bitstream...]`; the stream byte count is `ceil(bit_count / 8)`, with a maximum of 262 bytes. Invalid input or failed internal round-trip returns -1. Null output or insufficient capacity returns -2 without writes.

The upstream notice identifies BYTEmark (tm), BYTE's Native Mode Benchmarks, and Rick Grehan of BYTE Magazine; the Linux/Unix port was by Uwe F. Mayer. The source's original as-is disclaimer is included in [LICENSE](LICENSE). NBench text generation (`create_text_block` and the word catalog) is replaced by the explicit bounded payload input; compression semantics remain in the port.

## Files

- Oracle: [nbench_huffman_compression_oracle.py](../nbench_huffman_compression_oracle.py)
- Workload: [workload.json](workload.json)
- Ports: C, C++, C3, Rust, Nim, Odin, V, Zig, Elisa under their respective `n/` directories.
