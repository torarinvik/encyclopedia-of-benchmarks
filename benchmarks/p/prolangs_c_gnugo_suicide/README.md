# Prolangs-C GNU Go suicide predicate

This package isolates `suicide.c::suicide` and the helper behavior it calls in the pinned GNU Go 1.1 source. It implements the source's bounded board decision, including its Ko exception, rather than a general Go engine or a complete modern ruleset.

## Contract

The `prolangs_c_gnugo_suicide` symbol uses the `i64_array_scalar_call` ABI. Input is `[row, column, own_color, opponent_move_color, ko_index, k, index_0, color_0, ...]`. It describes a pre-move 19x19 board, with omitted cells empty. The candidate coordinate must be empty; colors are 1 and 2 and must differ; `ko_index` is `-1` for no remembered Ko point or a row-major index in `0..360`. Duplicate listed cells and malformed values return `-1`.

The source checks liberties of the proposed opponent stone first. If any liberty exists, it returns 0 (accepted). If the move has no liberty, the source places that stone, evaluates every own-color group, and counts the individual own stones in groups with zero liberties. It returns 1 (rejected) when that count is zero, or when it is exactly one and the candidate is the remembered Ko point; otherwise it returns 0. The package preserves this source decision and does not attempt broader rules such as superko, scoring, or full capture mutation. Input is bounded to 120 listed stones and 246 words. This bound keeps the source's `unsigned char l[19][19]` liberty projection below its 256 wrap point: a connected group of at most 120 stones has at most 242 incident neighboring cells, with board-edge omissions reducing the count.

## Source and rights

The pinned source is [`suicide.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/gnugo/suicide.c), with helper semantics from [`eval.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/gnugo/eval.c), [`countlib.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/gnugo/countlib.c), and [`count.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/gnugo/count.c), all at commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The launcher [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/gnugo/info.sh) builds the full program; this package measures only the move predicate.

The source headers explicitly grant modification and redistribution under GNU General Public License version 1 and disclaim warranty. Attribution is GNU Go 1.1, Copyright (C) Free Software Foundation, Inc.; written by Man L. Li, modified by Wayne Iba, documented by Bob Webber. See [LICENSE.txt](LICENSE.txt). The ports are derivative implementations licensed under GNU GPL version 1.

## Workload and ports

See [workload.json](workload.json) and the independent reference model [`benchmarks/prolangs_c_gnugo_suicide_oracle.py`](../../prolangs_c_gnugo_suicide_oracle.py).

| Language | Port |
| --- | --- |
| C | `c/p/prolangs_c_gnugo_suicide.c` |
| C3 | `c3/p/prolangs_c_gnugo_suicide.c3` |
| C++ | `cpp/p/prolangs_c_gnugo_suicide.cpp` |
| Elisa | `elisa/p/prolangs_c_gnugo_suicide.elisa` |
| Nim | `nim/p/prolangs_c_gnugo_suicide.nim` |
| Odin | `odin/p/prolangs_c_gnugo_suicide.odin` |
| Rust | `rust/p/prolangs_c_gnugo_suicide.rs` |
| V | `v/p/prolangs_c_gnugo_suicide.v` |
| Zig | `zig/p/prolangs_c_gnugo_suicide.zig` |
