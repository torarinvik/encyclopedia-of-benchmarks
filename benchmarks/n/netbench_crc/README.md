# NetBench CRC update kernel

This package implements the `gen_crc_table` and `update_crc` operations from [`Trimaran/netbench-crc`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Trimaran/netbench-crc), pinned at commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The upstream `info.sh` compiles `crc32.c` and `packet.c`; its launcher runs the CRC update over a packet trace 1,000 times in the small profile or 40,000 times otherwise.

The bounded `netbench_crc` profile isolates one `update_crc(0, data, length)` call. Its `i64_array_scalar` input is a byte sequence represented as one signed 64-bit integer per byte, with each value in `0..255` and at most 256 bytes. The source uses `unsigned long` for its accumulator and table. To make behavior stable across language targets, this profile fixes that state width to 64 bits with unsigned wraparound, as in the LP64 environment, then returns the low 32 bits printed by the source's `(unsigned) crc_accum` conversion. The printed low 32 bits are invariant to whether `unsigned long` is 32 or 64 bits because only the low 32 bits affect the returned byte index and result. Empty input returns zero; invalid inputs return `-1`.

The launcher’s packet generation, 10,000-entry packet data tables, loop count, and text output are outside this bounded function contract. The kernel's CRC polynomial, table-generation order, byte indexing, and per-byte update order are retained. The independently written ports are in C, C3, C++, Elisa, Nim, Odin, Rust, V, and Zig. The full NetBench permission and redistribution notice from the pinned source is preserved in [`LICENSE_NOTICE.txt`](LICENSE_NOTICE.txt).

The independent expected-value model is [`benchmarks/netbench_crc_oracle.py`](../../netbench_crc_oracle.py). The checked workload is [`workload.json`](workload.json).

The package uses the `i64_array_scalar` ABI family:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm netbench_crc --language c
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/n/netbench_crc/c/build.json
```
