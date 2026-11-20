# Rights and provenance

The algorithm profile is a clean-room implementation of the published
Liu-Sun adaptive bottom-up block-merging idea, using Excesses IBFS as the local
max-flow solver as identified by the fcBK benchmark inventory. Sources:

- Liu and Sun, [“Parallel Graph-cuts by Adaptive Bottom-up Merging”](https://doi.org/10.1109/CVPR.2010.5539898).
- Goldberg et al., [“Faster and More Dynamic Maximum Flow by Incremental Breadth-First Search”](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/11/ghkktw_ESA2015.pdf).
- [fcBK max-flow benchmark inventory](https://github.com/fcBK-maxflow/fcBK-benchmark), used to identify `peibfs` as the adaptive-merge method with EIBFS subsolves.
- Jensen et al., [“Review of Serial and Parallel Min-Cut/Max-Flow Algorithms for Computer Vision”](https://arxiv.org/abs/2202.00418), for the high-level merging context.

Only algorithm descriptions and bibliographic metadata are used. No third-party
implementation code, benchmark inputs, or prose is included. The deterministic
bounded merge priority and search-tree restart behavior are fully specified in
the local README and workload. The source repositories' licenses do not apply
to these independently written files.
