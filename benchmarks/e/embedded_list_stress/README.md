# Embedded list stress

This is a bounded algorithm-kernel variant based on the linked-list workload in EEMBC's embedded benchmark sources. It is not the official benchmark and produces no benchmark score. The pinned lineage is `nfinit/ansibench` at `ef90abd09d7b7bb1f2809f896d6f67fb9724bebe`, source `coremark/src/core_list_join.c` and `coremark/src/core_util.c`.

## Contract

Input is `[item_count, seed, find_count, finder_index_mode]` as signed i64 values. Item count is 4–32, seed 1–255, find count 0–32, and finder mode is -1 (search by data byte) or 1 (search by index). Initialization follows the source's sentinel nodes, data pattern, index pattern, and initial index sort. Each search is followed by full pointer reversal and the source-style next-item cache splice. The kernel then performs stable bottom-up linked-list mergesorts using a cached data comparator and an index comparator; the index comparator regenerates the low data byte from the high byte. It removes and restores one item and performs the source CRC16 passes. Since the source's complex comparator calls the separate matrix/state kernels, this standalone bounded variant substitutes a deterministic cached 7-bit projection `(data16 ^ (data16 >> 8) ^ seed) & 0x7f`; this keeps the two-comparator list workload independent.

Output is the two-byte little-endian CRC result. Invalid input returns -1; null output or capacity below 2 returns -2 without writes.

The upstream source attribution is Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC), with original source by Shay Gal-on. The applicable source license is Apache License 2.0. See the included license notice and the pinned source references. This bounded kernel variant is not presented as an official benchmark result.

## Files

- Oracle: [embedded_list_stress_oracle.py](../embedded_list_stress_oracle.py)
- Workload: [workload.json](workload.json)
- Ports: C, C++, C3, Rust, Nim, Odin, V, Zig, Elisa under their respective `e/` directories.
