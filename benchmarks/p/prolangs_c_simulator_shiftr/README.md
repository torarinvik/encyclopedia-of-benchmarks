# Prolangs-C simulator SIC/XE arithmetic right shift

This package isolates `Prolangs-C/simulator/instruct2.c::SHIFTR_P`. It applies the SIC/XE simulator’s sign-extending right shift to one 24-bit register value. The source decodes the format-2 operand byte through `FORMAT2`: its high nibble selects the destination register and its low nibble encodes shift-count-minus-one.

## Contract

The `prolangs_c_simulator_shiftr` symbol uses the `i64_array_scalar_call` ABI with exactly two words: `[format2_operand_byte, register_value]`. The byte is in `0..255`, its high nibble must select one of the simulator’s 10 registers, and the value is a 24-bit unsigned register bit pattern. The shift distance is `(byte & 15) + 1`, so 1 through 16 positions are supported. Result is the 24-bit unsigned bit pattern after sign-extending arithmetic right shift. Malformed input returns `-1`.

The implementation preserves `SHIFTR_P`’s bit order: output bit positions through `REG2` repeat the source word’s most-significant bit; remaining positions copy `REG_BITS[LOOP-REG2-1]`. It excludes PC mutation, debugging output, interrupts, and unrelated format-2 instructions.

## Source and rights

Pinned sources at commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`: [`instruct2.c::SHIFTR_P`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/simulator/instruct2.c), [`format.c::FORMAT2`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/simulator/format.c), and [`machine.c::BYTES_TO_BITS`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/simulator/machine.c). Launcher: [`Prolangs-C/simulator/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/simulator/info.sh).

The source permission notice is “(c) William Landi 1991. Permission to use this code is granted as long as the copyright notice remains in place.” It is preserved in all ports and [LICENSE.txt](LICENSE.txt). Ports are independent bounded implementations; no source code is copied.

## Workload and ports

See [workload.json](workload.json) and the independent bit-position model at [`benchmarks/prolangs_c_simulator_shiftr_oracle.py`](../../prolangs_c_simulator_shiftr_oracle.py).

| Language | Port |
| --- | --- |
| C | `c/p/prolangs_c_simulator_shiftr.c` |
| C3 | `c3/p/prolangs_c_simulator_shiftr.c3` |
| C++ | `cpp/p/prolangs_c_simulator_shiftr.cpp` |
| Elisa | `elisa/p/prolangs_c_simulator_shiftr.elisa` |
| Nim | `nim/p/prolangs_c_simulator_shiftr.nim` |
| Odin | `odin/p/prolangs_c_simulator_shiftr.odin` |
| Rust | `rust/p/prolangs_c_simulator_shiftr.rs` |
| V | `v/p/prolangs_c_simulator_shiftr.v` |
| Zig | `zig/p/prolangs_c_simulator_shiftr.zig` |
