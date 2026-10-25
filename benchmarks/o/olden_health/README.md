# Olden health system

This package models the pinned Olden `health` benchmark: a seeded discrete-time health-care simulation over a four-way village tree. Each village has a hospital with assessment, waiting, and inside queues; patients may be discharged after treatment or referred to the parent village.

## Bounded contract

- ABI: `i64_array_scalar`, function symbol `olden_health`.
- Input is `[max_level, max_time, seed]`. The local profile accepts levels 1 through 4, 0 through 40 ticks, and seed 1. This keeps the tree to at most 85 villages and caps newly created patients at 3,400. The pinned launcher requests levels 8/10; those larger profiles are outside this portable workload bound.
- Village labels follow `child = parent * 4 + child_offset` for offsets 1..4. The simulation visits children in source order 3,2,1,0 before processing the parent.
- Every tick transfers referrals from children, processes inside patients, processes assessments with the pinned Park-Miller/XOR float32 recurrence, promotes waiting patients, and creates at most one new patient at each village.
- The scalar result is the number of patients discharged during the requested ticks, corresponding to the source's reported treated-patient total. Invalid framing, levels, tick counts, or seeds return -1.
- The independent Python oracle uses per-village FIFO queues rather than the ports' bounded intrusive queue representation.

## Provenance and license

The sources are [`args.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/health/args.c), [`health.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/health/health.c), [`health.h`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/health/health.h), [`list.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/health/list.c), and [`poisson.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/health/poisson.c) at commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. `info.sh` selects `[8,15,1]` for the small profile and `[10,40,1]` otherwise. The source comments refer to `olden_v1.0/COPYRIGHT`, but that file is absent from the pinned snapshot; no license is inferred. These ports are independently written from the observed model and queue rules.

The static workload is [`workload.json`](workload.json); the independent oracle is [`benchmarks/olden_health_oracle.py`](../../olden_health_oracle.py).

## Language ports

| Language | Implementation |
| --- | --- |
| C | [`c/o/olden_health.c`](../../../c/o/olden_health.c) |
| C3 | [`c3/o/olden_health.c3`](../../../c3/o/olden_health.c3) |
| C++ | [`cpp/o/olden_health.cpp`](../../../cpp/o/olden_health.cpp) |
| Elisa | [`elisa/o/olden_health.elisa`](../../../elisa/o/olden_health.elisa) |
| Nim | [`nim/o/olden_health.nim`](../../../nim/o/olden_health.nim) |
| Odin | [`odin/o/olden_health.odin`](../../../odin/o/olden_health.odin) |
| Rust | [`rust/o/olden_health.rs`](../../../rust/o/olden_health.rs) |
| V | [`v/o/olden_health.v`](../../../v/o/olden_health.v) |
| Zig | [`zig/o/olden_health.zig`](../../../zig/o/olden_health.zig) |
