# MediaBench GSM RPE grid selection

This package isolates the GSM RPE encoder's four-phase grid-selection kernel.
It evaluates the four possible offsets in a 40-sample weighted residual,
chooses the offset with greatest energy after arithmetic right shift by two,
and emits that grid's 13 samples. It does not implement the GSM weighting
filter, APCM quantizer, inverse quantizer, RPE positioning, speech encoder,
frame bit packing, file handling, or toast command-line workload.

## Contract

The exported symbol is `mediabench_gsm_rpe_grid_selection` with the
`i64_array_bytes_output` ABI. Input is exactly 40 signed integer samples in
the source's signed 16-bit range. For grid `m` in `0..3`, score
`2 * sum((floor(x[m+3*i]/4))^2)` for `i=0..12`; the common factor 2 does not
change selection but is retained in the source-derived score definition.
Choose the first grid with the maximum score, matching the source's strict
`>` updates, then return `[grid, x[grid], x[grid+3], ..., x[grid+36]]` as
fourteen signed 64-bit little-endian words (112 bytes). Negative shifts use
arithmetic/floor semantics. Bounds keep the exact score within signed 32-bit
range.

Malformed length or out-of-range samples return `-1`. A null or short output
returns `-2` after input validation. Success returns 112 and writes all bytes;
errors leave output untouched. The independent oracle is
[`mediabench_gsm_rpe_grid_selection_oracle.py`](../../mediabench_gsm_rpe_grid_selection_oracle.py);
the fixed and malformed cases are in [`workload.json`](workload.json).

## Pinned source and rights

The kernel is `RPE_grid_selection` in
[`mediabench/gsm/toast/rpe.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/mediabench/gsm/toast/rpe.c)
at lac-dcc/Benchmarks commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The source launcher is
[`mediabench/gsm/toast/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/mediabench/gsm/toast/info.sh),
which encodes the bundled `clinton.pcm` input. The adjacent `COPYRIGHT` file
permits any use provided its notice is retained and disclaims warranty; the
complete notice is included as [`COPYRIGHT.txt`](COPYRIGHT.txt) and summarized
in [`LICENSE.txt`](LICENSE.txt). The ports
are independent implementations of the described finite operation and do
not copy the upstream function body.

## Ports

- C: [`c/m/mediabench_gsm_rpe_grid_selection.c`](../../../c/m/mediabench_gsm_rpe_grid_selection.c)
- C3: [`c3/m/mediabench_gsm_rpe_grid_selection.c3`](../../../c3/m/mediabench_gsm_rpe_grid_selection.c3)
- C++: [`cpp/m/mediabench_gsm_rpe_grid_selection.cpp`](../../../cpp/m/mediabench_gsm_rpe_grid_selection.cpp)
- Elisa: [`elisa/m/mediabench_gsm_rpe_grid_selection.elisa`](../../../elisa/m/mediabench_gsm_rpe_grid_selection.elisa)
- Nim: [`nim/m/mediabench_gsm_rpe_grid_selection.nim`](../../../nim/m/mediabench_gsm_rpe_grid_selection.nim)
- Odin: [`odin/m/mediabench_gsm_rpe_grid_selection.odin`](../../../odin/m/mediabench_gsm_rpe_grid_selection.odin)
- Rust: [`rust/m/mediabench_gsm_rpe_grid_selection.rs`](../../../rust/m/mediabench_gsm_rpe_grid_selection.rs)
- V: [`v/m/mediabench_gsm_rpe_grid_selection.v`](../../../v/m/mediabench_gsm_rpe_grid_selection.v)
- Zig: [`zig/m/mediabench_gsm_rpe_grid_selection.zig`](../../../zig/m/mediabench_gsm_rpe_grid_selection.zig)

No tests, builds, or runtime checks are claimed.
