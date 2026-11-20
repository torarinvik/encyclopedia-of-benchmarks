# Lovasz-toggle defective coloring trace

This profile applies the Lovasz toggle process to a bounded simple graph. The
algorithm repeatedly flips a bad vertex until each red vertex has at most `r`
red neighbors and each blue vertex has at most `b` blue neighbors. A vertex is
bad when it exceeds its own color's same-color degree limit.

## Contract

- Input is `[n,r,b,red_mask,m,(u,v)*m]`: `0<=n<=16`, `1<=r,b<=8`, and
  `0<=m<=n(n-1)/2`. Bit `i` of `red_mask` is set exactly when vertex `i` starts
  red. Each edge must be canonical (`0<=u<v<n`) and appear once.
- The graph must have maximum degree at most `r+b+1`, the condition in the
  Lovasz two-coloring theorem. The next vertex to flip is always the
  lowest-index currently bad vertex. This makes the trace deterministic.
- Return `(toggle_count << n) | final_red_mask`. Thus both the number of
  recolorings and the terminal coloring are observable. Invalid framing,
  duplicate or noncanonical edges, an invalid threshold, an out-of-range mask,
  a degree-bound violation, or null input returns `-1`.
- The maximum valid frame has 245 words; one trailing word is admitted for
  rejection at the 246-word parse limit. The fixed workspace is 4,096 bytes.

Termination follows from a weighted monochromatic-edge potential. Give each
red-red edge weight `b` and each blue-blue edge weight `r`. Flipping a bad red
vertex decreases the potential by at least `b`; flipping a bad blue vertex
decreases it by at least `r`, using maximum degree `r+b+1`. The potential is
nonnegative and at most `max(r,b)*m`, so at most 960 flips occur in this
profile. The primary oracle stores each neighbor row as a fixed-width bit mask;
the language ports use bounded adjacency arrays or masks. The independent
reference stores adjacency sets and a color vector.

## Provenance and suite

The candidate appears in KTH's [KACTL techniques index](https://github.com/kth-competitive-programming/kactl/blob/main/content/appendix/techniques.txt).
The constructive rule and degree condition are described in the University of
Chicago notes on [Lovasz Toggle](https://people.cs.uchicago.edu/~laci/reu03/notes13/node3.html).
The package is a clean-room algorithm benchmark; no upstream code or prose was
copied. It is registered in the shared `i64_array_scalar` suite.

| Language | Port |
| --- | --- |
| C | [`c/l/lovasz_toggle_defective_coloring_trace.c`](../../../c/l/lovasz_toggle_defective_coloring_trace.c) |
| C3 | [`c3/l/lovasz_toggle_defective_coloring_trace.c3`](../../../c3/l/lovasz_toggle_defective_coloring_trace.c3) |
| C++ | [`cpp/l/lovasz_toggle_defective_coloring_trace.cpp`](../../../cpp/l/lovasz_toggle_defective_coloring_trace.cpp) |
| Elisa | [`elisa/l/lovasz_toggle_defective_coloring_trace.elisa`](../../../elisa/l/lovasz_toggle_defective_coloring_trace.elisa) |
| Mojo | [`mojo/l/lovasz_toggle_defective_coloring_trace.mojo`](../../../mojo/l/lovasz_toggle_defective_coloring_trace.mojo) |
| Nim | [`nim/l/lovasz_toggle_defective_coloring_trace.nim`](../../../nim/l/lovasz_toggle_defective_coloring_trace.nim) |
| Odin | [`odin/l/lovasz_toggle_defective_coloring_trace.odin`](../../../odin/l/lovasz_toggle_defective_coloring_trace.odin) |
| Rust | [`rust/l/lovasz_toggle_defective_coloring_trace.rs`](../../../rust/l/lovasz_toggle_defective_coloring_trace.rs) |
| V | [`v/l/lovasz_toggle_defective_coloring_trace.v`](../../../v/l/lovasz_toggle_defective_coloring_trace.v) |
| Zig | [`zig/l/lovasz_toggle_defective_coloring_trace.zig`](../../../zig/l/lovasz_toggle_defective_coloring_trace.zig) |
