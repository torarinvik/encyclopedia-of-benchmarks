# Prolangs-C two-pass assembler

This package implements a bounded SIC/XE assembler core based on the pinned Prolangs-C assembler. Pass one assigns locations and resolves symbol definitions; pass two emits format-2 and format-3 instruction words and `WORD` constants. It preserves forward-reference resolution and the source's PC-relative format-3 addressing for labeled operands.

## Contract

The scalar ABI is `int64_t prolangs_c_assembler(const int64_t *input, size_t length)`. The input is `[record_count, (opcode_id, label_id, operand_kind, operand_value)*]`, with two through 16 records. The first record must be `START` and the last must be `END`.

| Opcode ID | Statement | Size |
| ---: | --- | ---: |
| 0 | `START` | 0 |
| 1 | `END` | 0 |
| 2 | `RESB` | operand bytes |
| 3 | `RESW` | three times operand words |
| 4 | `WORD` | 3 |
| 5 | `LDA` | 3 |
| 6 | `STA` | 3 |
| 7 | `ADD` | 3 |
| 8 | `J` | 3 |
| 9 | `RSUB` | 3 |
| 10 | `CLEAR` | 2 |
| 11 | `ADDR` | 2 |

`label_id` is zero for no label or 1 through 16 for a symbol. The `START` label is required, labels may be forward-referenced, and duplicate labels are invalid. Operand kinds are zero for directives and `RSUB`, 1 for an immediate numeric format-3 operand, 2 for a simple label reference, 3 for an indirect label reference, 4 for a `CLEAR` register ID, and 5 for an `ADDR` register pair packed as `first_register * 16 + second_register`. Register IDs are A=0, X=1, L=2, B=3, S=4, and T=5.

The start address is in `0..0xFFFFF`; reserve counts are in `0..256`; `WORD` values are unsigned 24-bit; immediate constants are in `0..4095`; and addresses must fit the SIC/XE 20-bit memory space. Format-3 label references use PC-relative displacement in `-2048..2047`. The checksum is updated per record as `(checksum * 131 + (address + 1) * 17 + object_code * 3 + size) mod 1,000,000,007`, seeded by `(program_length * 257 + start_address * 17) mod 1,000,000,007`. Invalid input or an undefined/out-of-range reference returns `-1`.

The bounded implementation uses numeric records instead of source-line parsing, external files, temporary pass files, listing text, and object-record buffers. It retains the two passes, symbol table behavior, opcode values, format-2 register fields, format-3 addressing flags, and relative displacement calculation for the documented subset.

## Workload and oracle

[`workload.json`](workload.json) covers a forward symbol reference, format-2 instructions, storage reservation, `WORD`, `RSUB`, malformed input, and an undefined label. [`benchmarks/prolangs_c_assembler_oracle.py`](../../prolangs_c_assembler_oracle.py) independently computes locations and symbols before emitting the bounded object-code checksum.

## Ports

| Language | Source |
| --- | --- |
| C | [`c/p/prolangs_c_assembler.c`](../../../c/p/prolangs_c_assembler.c) |
| C3 | [`c3/p/prolangs_c_assembler.c3`](../../../c3/p/prolangs_c_assembler.c3) |
| C++ | [`cpp/p/prolangs_c_assembler.cpp`](../../../cpp/p/prolangs_c_assembler.cpp) |
| Elisa | [`elisa/p/prolangs_c_assembler.elisa`](../../../elisa/p/prolangs_c_assembler.elisa) |
| Nim | [`nim/p/prolangs_c_assembler.nim`](../../../nim/p/prolangs_c_assembler.nim) |
| Odin | [`odin/p/prolangs_c_assembler.odin`](../../../odin/p/prolangs_c_assembler.odin) |
| Rust | [`rust/p/prolangs_c_assembler.rs`](../../../rust/p/prolangs_c_assembler.rs) |
| V | [`v/p/prolangs_c_assembler.v`](../../../v/p/prolangs_c_assembler.v) |
| Zig | [`zig/p/prolangs_c_assembler.zig`](../../../zig/p/prolangs_c_assembler.zig) |

## Source and rights

The source is pinned to [`lac-dcc/Benchmarks` at `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/assembler). The inspected files include `info.sh`, `assem.c`, `pass1.c`, `pass2.c`, `op_tab.c`, `code.c`, and `constants.h`. The launcher builds the assembler's pass, scanner, opcode, pseudo-op, symbol-table, and record modules and runs `assem` without a fixed input file.

Every port retains the source notice verbatim and identifies the numeric-record adaptation:

> (c) William Landi 1991. Permission to use this code is granted as long as the copyright notice remains in place.
