# Rights and provenance

The algorithm profile is derived from the forward operation in `GGNN_Aggregator::aggregate`
and `ggnn_aggregate_all`, `ggnn_compute_gates_and_candidate`, and
`ggnn_out_warp` at the pinned GraphAIBench revision listed in `workload.json`.
The pinned source tree is <https://github.com/chenxuhao/GraphAIBench/tree/17834cb29b7c542481c2e3740dc9664841b72f59>.
The ten implementations and both Python oracles were written independently
from the operation description and formulas. No upstream source code, tests,
or prose was copied.

GraphAIBench is distributed under the MIT License, copyright (c) 2022 Xuhao
Chen. Its full notice is retained in `LICENSE.txt`. The local profile accepts
all six matrices as input, fixes a small CSR graph and feature domain, and
uses binary64 arithmetic. It does not include the repository's random
initialization, CUDA kernels, optimizer, training, or gradient calculations.
