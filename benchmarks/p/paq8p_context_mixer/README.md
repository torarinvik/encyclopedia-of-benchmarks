# PAQ8p bounded context mixer

This package isolates the adaptive neural `Mixer` component in PAQ8p. It is a bounded profile of the source component, not a PAQ8p compressor benchmark: the PAQ context models, byte/file filters, predictor context construction, arithmetic coder, archive format, and file handling are excluded.

## Contract

The exported `paq8p_context_mixer` uses `i64_array_bytes_output`. Input is `[steps, (context_a, context_b, target_bit, x0, ..., x7) * steps]`, with 1–16 steps. Each context selector and target is 0 or 1; each of the eight feature inputs is a signed stretched prediction in `[-2047,2047]`. The selected PAQ Mixer configuration is `Mixer(N=8,M=4,S=2,w=0)` with its source-created nested `Mixer(N=2,M=1,S=1,w=0x7fff)`. The two selectors address one expert from each of two groups of two weight rows.

For every step, each expert computes the source fixed-point dot product, shifts by five, and applies `squash`; the nested combiner receives the inverse-table `stretch` values and returns a 12-bit `squash` prediction. After that prediction, both selected experts are trained against the target bit. At the next prediction, the nested combiner is trained against the previous bit, matching the source's nested `Mixer::p` update schedule. Training uses PAQ8p's pairwise `>>8` dot-product accumulation, error scale 7, fixed-point weight increment, and signed-16-bit weight clamp.

The output is one little-endian unsigned 16-bit prediction per step (values 0–4095); success returns `2*steps`. Invalid framing, selector, target, or feature returns `-1`. Null output or insufficient capacity returns `-2` after input validation. The workload and oracle keep initialization, expert indexing, update timing, `squash`, and the source-generated inverse `stretch` table explicit.

## Provenance and scope

The profile is based on `PAQ8p/paq8p.cpp` at pinned `lac-dcc/Benchmarks` revision `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`, specifically `squash`, `Stretch`, `dot_product`, `train`, `Mixer`, and its nested combiner. The launcher `PAQ8p/info.sh` runs the complete file compressor; this package only measures the mixer update kernel with a bounded, caller-supplied feature trace. It must not be reported as full PAQ compression coverage.

The source declares Copyright (C) 2008 Matt Mahoney, Serge Osnach, Alexander Ratushnyak, Bill Pettis, Przemyslaw Skibinski, Matthew Fite, wowtiger, Andrew Paterson, Jan Ondrus, Andreas Morphis, Pavel L. Holoborodko, and KZ, under the GNU General Public License version 2 or (at the user's option) any later version. See [`LICENSE.txt`](LICENSE.txt). All nine package ports are GPL-2.0-or-later.

## Workload and ports

The independent model is [`benchmarks/paq8p_context_mixer_oracle.py`](../../paq8p_context_mixer_oracle.py); fixtures and bounds are in [`workload.json`](workload.json).

| Language | Port |
| --- | --- |
| C | [`c/p/paq8p_context_mixer.c`](../../../c/p/paq8p_context_mixer.c) |
| C3 | [`c3/p/paq8p_context_mixer.c3`](../../../c3/p/paq8p_context_mixer.c3) |
| C++ | [`cpp/p/paq8p_context_mixer.cpp`](../../../cpp/p/paq8p_context_mixer.cpp) |
| Elisa | [`elisa/p/paq8p_context_mixer.elisa`](../../../elisa/p/paq8p_context_mixer.elisa) |
| Nim | [`nim/p/paq8p_context_mixer.nim`](../../../nim/p/paq8p_context_mixer.nim) |
| Odin | [`odin/p/paq8p_context_mixer.odin`](../../../odin/p/paq8p_context_mixer.odin) |
| Rust | [`rust/p/paq8p_context_mixer.rs`](../../../rust/p/paq8p_context_mixer.rs) |
| V | [`v/p/paq8p_context_mixer.v`](../../../v/p/paq8p_context_mixer.v) |
| Zig | [`zig/p/paq8p_context_mixer.zig`](../../../zig/p/paq8p_context_mixer.zig) |
