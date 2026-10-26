# Prolangs-C GNU Go group liberty count

This package isolates the `countlib` / `count` operation from the pinned GNU Go 1.1 benchmark. Given a selected stone, it traverses its orthogonally connected group of the selected color and counts each distinct adjacent empty intersection once. This is the Go group-liberty operation, not merely an arbitrary connected-component size.

## Contract

The `prolangs_c_gnugo_liberty_count` symbol uses the `i64_array_scalar_call` ABI. The input is `[row, column, color, k, index_0, color_0, ..., index_(k-1), color_(k-1)]`. It describes a fixed 19x19 board; each row-major index is in `0..360`, stone colors are 1 and 2, and omitted cells are empty. The selected coordinate must contain the selected color. Duplicate indices, malformed lengths, invalid coordinates/colors, or an empty/mismatched selected cell return `-1`.

The bound is `k <= 361`, so the maximum input has 726 signed 64-bit words. Success is the number of unique orthogonally adjacent empty cells, in the range 0..361. Input validation is completed before traversal. Ports use bounded board/visited/stack storage; the source's recursive depth-first walk is represented with an explicit stack while preserving the same group/liberty semantics.

## Source and rights

Source: [`countlib.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/gnugo/countlib.c) and [`count.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/gnugo/count.c), pinned at `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The launcher is [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/gnugo/info.sh), which builds the full GNU Go program and supplies `stdin`. This package benchmarks only group liberty counting, not move generation, board evaluation, or the full game program.

The source headers explicitly grant modification and redistribution under GNU GPL version 1 and disclaim warranty. Attribution is GNU Go 1.1, Copyright (C) Free Software Foundation, Inc.; written by Man L. Li, modified by Wayne Iba, documented by Bob Webber. See [LICENSE.txt](LICENSE.txt). The package ports are derivative implementations under GNU GPL version 1 and do not copy upstream source text.

## Workload and ports

See [workload.json](workload.json) and the independent graph-traversal model at [`benchmarks/prolangs_c_gnugo_liberty_count_oracle.py`](../../prolangs_c_gnugo_liberty_count_oracle.py).

| Language | Port |
| --- | --- |
| C | `c/p/prolangs_c_gnugo_liberty_count.c` |
| C3 | `c3/p/prolangs_c_gnugo_liberty_count.c3` |
| C++ | `cpp/p/prolangs_c_gnugo_liberty_count.cpp` |
| Elisa | `elisa/p/prolangs_c_gnugo_liberty_count.elisa` |
| Nim | `nim/p/prolangs_c_gnugo_liberty_count.nim` |
| Odin | `odin/p/prolangs_c_gnugo_liberty_count.odin` |
| Rust | `rust/p/prolangs_c_gnugo_liberty_count.rs` |
| V | `v/p/prolangs_c_gnugo_liberty_count.v` |
| Zig | `zig/p/prolangs_c_gnugo_liberty_count.zig` |
