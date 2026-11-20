# Rights and provenance

The benchmark is an independent implementation of a bounded deterministic
profile of adaptive bottom-up graph-cut merging. Its algorithmic provenance is
Liu and Sun's [CVPR 2010 paper](https://doi.org/10.1109/CVPR.2010.5539898) and
the later Jensen et al. [review](https://arxiv.org/abs/2202.00418). The review
describes independent block solves, restoring boundary arcs when blocks merge,
and merge prioritization by potential new augmenting paths. The authors'
later [`maxflow_algorithms` reimplementation](https://github.com/patmjen/maxflow_algorithms/blob/master/reimpls/liusun.h)
is MIT licensed; it is consulted only to define a concrete potential-count
profile. No upstream source text, code, or benchmark data is copied.

This profile uses deterministic Edmonds–Karp residual augmentation instead of
the paper's Boykov–Kolmogorov tree-reuse solver and serializes the schedule.
The benchmark does not claim exact reproduction of the paper implementation.
