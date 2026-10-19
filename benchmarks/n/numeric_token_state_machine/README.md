# Numeric token state machine

This package is a bounded algorithm-kernel variant of the numeric-token finite state machine in EEMBC's embedded benchmark source. It is not the official benchmark and produces no benchmark score. Its pinned source is `nfinit/ansibench` commit `ef90abd09d7b7bb1f2809f896d6f67fb9724bebe`, `coremark/src/core_state.c` and `coremark/include/coremark.h`.

## Contract

Input is a signed i64 array `[byte_count, corruption_step, seed, ASCII bytes...]`. It contains 1–96 printable ASCII bytes, comma-separated nonempty tokens, with no NUL. The step is 1–16 and seed is 1–255. To preserve the source's NUL-terminated scans and conditional corruption/restoration loops, every byte selected for XOR must remain neither NUL nor comma after corruption. The FSM uses the upstream eight-state order: START, INVALID, S1, S2, INT, FLOAT, EXPONENT, SCIENTIFIC. It scans the original input, corrupts every `step`th byte starting at offset zero except commas by XOR with `seed`, scans again, and restores the bytes with the same XOR. Output is 64 bytes: for each state in enum order, final token count then accumulated transition count, each u32 little-endian. Counts combine both scans. Invalid input returns -1; null output or capacity below 64 returns -2 without writes.

The source attribution is Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC), with original source by Shay Gal-on. The source subtree's applicable license is Apache License 2.0; see the included license notice and pinned source references. This local kernel variant is independently bounded and does not claim official benchmark results.

## Files

- Oracle: [numeric_token_state_machine_oracle.py](../numeric_token_state_machine_oracle.py)
- Workload: [workload.json](workload.json)
- Ports: C, C++, C3, Rust, Nim, Odin, V, Zig, Elisa under their respective `n/` directories.
