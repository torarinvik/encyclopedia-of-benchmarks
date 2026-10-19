# Revert bits

This package ports the 32-bit and 64-bit reversal routines in
[`lac-dcc/Benchmarks/Misc/revertBits/revertBits.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/revertBits/revertBits.c)
at pinned commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Its launcher names
`revertBits.c` and passes `-lm`; the implementation itself uses staged integer
bit operations.

The existing `reverse_bits` benchmark covers only a 32-bit word. This package
adds the upstream pair of fixed-width operations: a 32-bit input and a full
64-bit input. It takes `[uint32_word, signed_i64_bit_pattern]`; the second value
is interpreted as an unsigned 64-bit word through its raw two's-complement
bits. Results are returned as four little-endian bytes for the 32-bit reversal,
followed by eight little-endian bytes for the 64-bit reversal. This preserves
all unsigned result bits even when the 64-bit result has its high bit set.

The workload includes the pinned source's `0x12345678` and
`0x0123456789012345` sample words, bit-position boundaries, invalid 32-bit
inputs, and output-buffer errors. The independent oracle is
[`benchmarks/revert_bits_oracle.py`](../../revert_bits_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [c/r/revert_bits.c](../../../c/r/revert_bits.c) |
| C3 | [c3/r/revert_bits.c3](../../../c3/r/revert_bits.c3) |
| C++ | [cpp/r/revert_bits.cpp](../../../cpp/r/revert_bits.cpp) |
| Elisa | [elisa/r/revert_bits.elisa](../../../elisa/r/revert_bits.elisa) |
| Nim | [nim/r/revert_bits.nim](../../../nim/r/revert_bits.nim) |
| Odin | [odin/r/revert_bits.odin](../../../odin/r/revert_bits.odin) |
| Rust | [rust/r/revert_bits.rs](../../../rust/r/revert_bits.rs) |
| V | [v/r/revert_bits.v](../../../v/r/revert_bits.v) |
| Zig | [zig/r/revert_bits.zig](../../../zig/r/revert_bits.zig) |

Run the shared byte-output suite with:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm revert_bits --language c
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/r/revert_bits/c/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm revert_bits --languages c
```
