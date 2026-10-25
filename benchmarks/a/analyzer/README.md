# FreeBench analyzer RAW dependency analysis

This package ports the default data-analysis core of the pinned FreeBench
`analyzer`. The original launcher chooses `test.in` when `SMALL_PROBLEM_SIZE`
is set and `ref.in` otherwise, then passes that trace file to the program.
With its default settings, the program counts memory operations, records
stores by epoch, and reports read-after-write (RAW) conflicts for loads whose
latest prior writer is in an earlier epoch. This benchmark retains that
dependency-detection core; it excludes file parsing, diagnostics, optional
configuration, and the separate speculative-time/speedup estimates.

## Contract

- ABI: `i64_array_scalar`, symbol `analyzer`.
- Input is `[event_count, (epoch, opcode, address)*]`; each trace row has an
  epoch, an opcode, and a byte-address token. `opcode` 0 is a store and 1 is a
  load. Rows are in source order and epoch numbers are nondecreasing, from 0
  through 15. Address tokens are in `0..255`.
- The event count is from 0 through 64 and the array length must equal
  `1 + 3*event_count`. Invalid counts, framing, row order, opcodes, or address
  tokens return `-1`.
- A load contributes one conflict when the most recent preceding store to its
  address is in an earlier epoch. A store in the load's own epoch supersedes
  older writers for later loads. Loads retain source order, so multiple loads
  can each contribute a conflict. The result is the total conflict count,
  equivalent to summing the source's per-address accesser counts.
- The nine ports scan earlier trace rows while retaining the latest writer
  position for each address. The [independent oracle](../../analyzer_oracle.py)
  instead tracks the latest writer epoch directly.

[`workload.json`](workload.json) covers same-epoch suppression, overwriting an
older writer, repeated loads, interleaved addresses, maximum addresses, and
malformed framing. The verifier also constructs deterministic bounded traces
with nondecreasing epochs.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm analyzer --language rust --with-checker
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/a/analyzer/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms analyzer --languages rust
```

## Provenance and license

The pinned `analyzer.c` header names Peter Rundberg and says, “Please feel free
to distribute this program as you like.” No separate formal license is
inferred. These ports and the oracle are independently written from the
published source behavior and do not copy the upstream implementation.

- [`analyzer.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/FreeBench/analyzer/analyzer.c)
- [Pinned analyzer source directory](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/FreeBench/analyzer)
- [`types.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/FreeBench/analyzer/types.c)
- [`functs.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/FreeBench/analyzer/functs.c)
- [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/FreeBench/analyzer/info.sh)

## Language ports

| Language | Source |
| --- | --- |
| C | [c/a/analyzer.c](../../../c/a/analyzer.c) |
| C3 | [c3/a/analyzer.c3](../../../c3/a/analyzer.c3) |
| C++ | [cpp/a/analyzer.cpp](../../../cpp/a/analyzer.cpp) |
| Elisa | [elisa/a/analyzer.elisa](../../../elisa/a/analyzer.elisa) |
| Nim | [nim/a/analyzer.nim](../../../nim/a/analyzer.nim) |
| Odin | [odin/a/analyzer.odin](../../../odin/a/analyzer.odin) |
| Rust | [rust/a/analyzer.rs](../../../rust/a/analyzer.rs) |
| V | [v/a/analyzer.v](../../../v/a/analyzer.v) |
| Zig | [zig/a/analyzer.zig](../../../zig/a/analyzer.zig) |
