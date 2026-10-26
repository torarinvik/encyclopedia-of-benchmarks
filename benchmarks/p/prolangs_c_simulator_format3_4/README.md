# Prolangs-C simulator FORMAT3/FORMAT4 address decode

This package isolates the address-demand path of `Prolangs-C/simulator/format.c::FORMAT3_4`. It decodes one SIC/XE instruction’s operand address for immediate, simple/direct, indexed, base-relative, PC-relative, or extended format. This is the simulator’s execution-side address interpretation; it is distinct from `prolangs_c_assembler`, which emits instruction encodings and object records.

## Contract

The `prolangs_c_simulator_format3_4` symbol uses the `i64_array_scalar_call` ABI. The fixed seven-word input is `[pc, X, B, byte0, byte1, byte2, byte3]`. `pc` is within the simulator’s 1 MiB memory, `X` and `B` are 24-bit nonnegative register values, and each byte is in `0..255`. The implementation advances PC by three or four bytes internally, matching the source’s use of the updated PC for PC-relative addressing, and returns the decoded nonnegative operand address. Negative effective addresses are outside the bounded profile so `-1` remains the invalid sentinel. Invalid source mode combinations and malformed input also return `-1`.

The profile models `DEMAND != VALUE_1`, so it returns addresses/immediate constants and does not read operand values from simulated memory. It covers format-3 simple and immediate, indexed/base/PC-relative addressing, and format-4 simple/immediate with optional indexing. It excludes indirect addressing, which dereferences three memory bytes, and value-demand loads, which read the requested number of bytes. Plane-SIC `n=i=0` reaches the source's final fallback return of zero despite first extracting the 12-bit field; this source behavior is preserved. Format-3 `b=p=1` and format-4 `b` or `p` flags follow the source's illegal-instruction path. The source's order of adding X/B before applying the PC-relative sign check is preserved.

## Source and rights

Pinned source: [`format.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/simulator/format.c), symbol `FORMAT3_4`; supporting constants are from [`constants.h`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/simulator/constants.h), all at commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Launcher: [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/simulator/info.sh).

The source header states: “(c) William Landi 1991” and “Permission to use this code is granted as long as the copyright notice remains in place.” This permission notice is preserved in every port and in [LICENSE.txt](LICENSE.txt). The ports are independently written implementations and include no copied source text.

## Workload and ports

See [workload.json](workload.json) and the independent reference model at [`benchmarks/prolangs_c_simulator_format3_4_oracle.py`](../../prolangs_c_simulator_format3_4_oracle.py).

| Language | Port |
| --- | --- |
| C | `c/p/prolangs_c_simulator_format3_4.c` |
| C3 | `c3/p/prolangs_c_simulator_format3_4.c3` |
| C++ | `cpp/p/prolangs_c_simulator_format3_4.cpp` |
| Elisa | `elisa/p/prolangs_c_simulator_format3_4.elisa` |
| Nim | `nim/p/prolangs_c_simulator_format3_4.nim` |
| Odin | `odin/p/prolangs_c_simulator_format3_4.odin` |
| Rust | `rust/p/prolangs_c_simulator_format3_4.rs` |
| V | `v/p/prolangs_c_simulator_format3_4.v` |
| Zig | `zig/p/prolangs_c_simulator_format3_4.zig` |
