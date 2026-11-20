# Transposed Direct Form II digital filter

This package filters a bounded integer sequence with the transposed Direct
Form II realization of a linear constant-coefficient filter. It measures the
shared delay-state update: each sample produces one output and advances a
single state chain. The call begins with zero state and retains no state
between calls.

## Contract

The exported symbol is `digital_filter_direct_form_ii_transposed` with the
`i64_array_bytes_output` ABI. Input is
`[N,L,a0,...,aL,b0,...,bL,x0,...,x(N-1)]`, where `N` is 0 through 32 and the
filter order `L` is 0 through 4. The denominator is normalized with `a0=1`;
all remaining coefficients are in `[-1,1]`, and samples are in `[-16,16]`.
The frame has exactly `N+2L+4` signed-i64 values.

For order `L>0`, the filter holds `L` signed-i64 states, initially zero. For
each input sample `x`, it computes `y=b0*x+d0`; then, in ascending stage order,
it replaces `d[j]` with the still-old `d[j+1]` (or zero at the final stage),
plus `b[j+1]*x-a[j+1]*y`. Order zero is the feedthrough `y=b0*x`. These integer
operations are exact under the bounded input. If `S_n` is the largest state
magnitude before sample `n`, then `S_(n+1)<=2*S_n+32`; with at most 32 samples,
all states and outputs are within signed-i64 range.

Each output sample is serialized as one little-endian signed-i64 word. A valid
nonempty call returns `8*N`; an empty filter input sequence returns zero and
accepts a null output. Null/malformed input, an invalid coefficient or sample,
or an incorrect frame returns `-1`. A valid nonempty call with null or short
output returns `-2` without writing. Input validation precedes output checks.
The maximum valid and parseable input frames are 44 and 45 words, maximum
output is 256 bytes, and the native workspace cap is 256 bytes excluding
caller-owned input and output.

## Algorithm distinction

The existing [`iir_filter`](../../i/iir_filter/README.md) evaluates the direct
difference equation by retaining input and output histories. This package
uses the transposed Direct Form II signal-flow realization and updates a
shared delay-state chain instead. The two methods implement the same transfer
function in exact arithmetic, but have different state representations and
per-sample data movement. The independent reference uses the direct
difference equation, not the transposed state recurrence.

## References and provenance

RosettaGit's [Apply a digital filter (direct form II transposed) task](https://rosettagit.org/tasks/apply-a-digital-filter-direct-form-ii-transposed/)
provided the discovery lead. Its task description identifies the filter
realization; no sample coefficients, signal, outputs, task wording, or code
were copied. The transposed and direct forms are cross-checked against the
University of Cambridge's [Digital Signal Processing lecture slides, pages
120–121](https://www.cl.cam.ac.uk/teaching/2122/DSP/dsp-slides.pdf). Package
contracts, integer fixtures, references, and ports are original to this
bounded profile. See [RIGHTS.md](RIGHTS.md).

## Workload and inventory

[`workload.json`](workload.json) pins small exact-integer filter traces and
validation/output-error cases. [`primary_oracle.py`](primary_oracle.py)
implements the transposed state chain; [`independent_oracle.py`](independent_oracle.py)
evaluates the input/output-history difference equation. The metadata-only
[`verify_workload.py`](verify_workload.py) reconciles both references with all
pinned bytes. [`check_inventory.py`](check_inventory.py) checks package files
and ten language paths without invoking native programs.

| Language | Source |
|---|---|
| C | `c/d/digital_filter_direct_form_ii_transposed.c` |
| C3 | `c3/d/digital_filter_direct_form_ii_transposed.c3` |
| C++ | `cpp/d/digital_filter_direct_form_ii_transposed.cpp` |
| Elisa | `elisa/d/digital_filter_direct_form_ii_transposed.elisa` |
| Mojo | `mojo/d/digital_filter_direct_form_ii_transposed.mojo` |
| Nim | `nim/d/digital_filter_direct_form_ii_transposed.nim` |
| Odin | `odin/d/digital_filter_direct_form_ii_transposed.odin` |
| Rust | `rust/d/digital_filter_direct_form_ii_transposed.rs` |
| V | `v/d/digital_filter_direct_form_ii_transposed.v` |
| Zig | `zig/d/digital_filter_direct_form_ii_transposed.zig` |
