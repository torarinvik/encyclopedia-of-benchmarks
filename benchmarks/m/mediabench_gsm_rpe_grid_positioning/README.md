# MediaBench GSM RPE grid positioning

This package isolates GSM's RPE reconstruction scatter. Given the selected
grid and thirteen decoded residual samples, it inserts the samples into the
40-sample residual vector at three-sample intervals and fills all other
positions with zero. This is the inverse placement step after RPE grid
selection; it does not choose a grid, quantize or decode the samples, update
the long-term predictor, or encode a GSM frame.

## Contract

The exported function is `mediabench_gsm_rpe_grid_positioning` and uses the
`i64_array_bytes_output` ABI. Input is exactly `[grid, xMp[0], ..., xMp[12]]`.
The grid is 0–3 and each sample is a signed 16-bit word. The operation forms
`ep[0..39]`, initially zero, then sets `ep[grid + 3*i] = xMp[i]` for
`i=0..12`. It returns the 40 signed 16-bit values in little-endian byte order
(80 bytes). Invalid input returns `-1`; null or insufficient output returns
`-2` without writing. Successful calls stage the result before writing.

The independent oracle is
[`mediabench_gsm_rpe_grid_positioning_oracle.py`](../../mediabench_gsm_rpe_grid_positioning_oracle.py).
The workload includes all four grid offsets, signed word boundaries, and
invalid framing cases.

## Source and rights

The source is `RPE_grid_positioning` in
[`mediabench/gsm/toast/rpe.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/mediabench/gsm/toast/rpe.c),
pinned at lac-dcc/Benchmarks commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38` (lines 363–398). Its launcher is
[`mediabench/gsm/toast/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/mediabench/gsm/toast/info.sh).
The adjacent `COPYRIGHT` permits any use provided the notice is retained and
disclaims warranty. The complete notice appears in
[`COPYRIGHT.txt`](COPYRIGHT.txt), [`LICENSE.txt`](LICENSE.txt), and each port.
The implementations restate the small scatter operation and do not copy the
upstream function body.

## Ports

- C: [`c/m/mediabench_gsm_rpe_grid_positioning.c`](../../../c/m/mediabench_gsm_rpe_grid_positioning.c)
- C3: [`c3/m/mediabench_gsm_rpe_grid_positioning.c3`](../../../c3/m/mediabench_gsm_rpe_grid_positioning.c3)
- C++: [`cpp/m/mediabench_gsm_rpe_grid_positioning.cpp`](../../../cpp/m/mediabench_gsm_rpe_grid_positioning.cpp)
- Elisa: [`elisa/m/mediabench_gsm_rpe_grid_positioning.elisa`](../../../elisa/m/mediabench_gsm_rpe_grid_positioning.elisa)
- Nim: [`nim/m/mediabench_gsm_rpe_grid_positioning.nim`](../../../nim/m/mediabench_gsm_rpe_grid_positioning.nim)
- Odin: [`odin/m/mediabench_gsm_rpe_grid_positioning.odin`](../../../odin/m/mediabench_gsm_rpe_grid_positioning.odin)
- Rust: [`rust/m/mediabench_gsm_rpe_grid_positioning.rs`](../../../rust/m/mediabench_gsm_rpe_grid_positioning.rs)
- V: [`v/m/mediabench_gsm_rpe_grid_positioning.v`](../../../v/m/mediabench_gsm_rpe_grid_positioning.v)
- Zig: [`zig/m/mediabench_gsm_rpe_grid_positioning.zig`](../../../zig/m/mediabench_gsm_rpe_grid_positioning.zig)

No runtime validation is claimed for this package.
