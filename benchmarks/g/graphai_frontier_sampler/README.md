# GraphAIBench deterministic frontier sampler

This package isolates the three-round branching frontier expansion in
`sample` from the pinned
[`src/sampling/omp_base.cc`](https://github.com/chenxuhao/GraphAIBench/blob/17834cb29b7c542481c2e3740dc9664841b72f59/src/sampling/omp_base.cc)
at GraphAIBench commit `17834cb29b7c542481c2e3740dc9664841b72f59`. The
source's MIT attribution is retained in `LICENSE.txt`; the implementations
are clean-room ports.

Input is `[n,m,r,roots[r],rowptr[n+1],colind[m],edge_choice[21*r]]`.
The profile keeps three expanding frontiers and the source loop's
with-replacement edge selection, but uses bounded fanouts `3,2,2` instead of
the source constants `15,10,10` so every sampled vertex can be returned within
the suite's output limit. Each explicit choice is a zero-based edge ordinal
within the current parent's CSR row; choices are laid out by round, then
frontier order, then child order. This replaces process-global `rand()` with
caller-supplied deterministic draws. Vertices with zero out-degree cannot be
expanded and make the input invalid.

The output contains the complete ordered frontiers concatenated as
`roots || hop1 || hop2 || hop3`, with sizes `r,3r,6r,12r`. Bounds are
`n<=8`, `m<=24`, `1<=r<=4`. Graph loading, random-number generation, printed
timings, and materializing a sampled subgraph are outside the profile.
Malformed input returns `-1`; null output or insufficient capacity returns
`-2` without writes. See `workload.json`,
`../../graphai_frontier_sampler_oracle.py`, and the suite's independent
verifier oracle.
