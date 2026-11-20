# Greedy influence maximization under the Linear Threshold model

This bounded profile implements the greedy seed-selection procedure in Chapter
710's “Greedy Algorithm” subsection (Fig. 1) for the chapter's random Linear
Threshold activation model. At each round it adds the unselected vertex with
the largest marginal increase in spread. Equal marginal sums choose the
smallest vertex ID.

## Bounded contract

Use `i64_array_bytes_output`, symbol
`influence_maximization_greedy_linear_threshold`, with input:

```text
[n,m,k,world_count,(u,v,weight)*m,draw[world_count*n]]
```

The graph is directed, with `1<=n<=8`, `0<=m<=24`, `0<=k<=n`, and
`1<=world_count<=8`. Directed self-loops and duplicate ordered edges are
rejected. Each edge has an integer influence weight in `0..=256`, and incoming
weights at each target may sum to at most 256. Draws are in `0..=255` and are
stored by world, then vertex ID. The maximum valid frame is 140 signed 64-bit
words; the parser accepts 141 words to reject a trailing-word frame safely.

For each world and target vertex, the draw selects an incoming edge using
consecutive half-open intervals in input-edge order. An edge of weight `w`
occupies `w` draw values; the unused part of `[0,256)` selects no parent.
Therefore each vertex has at most one triggering incoming edge in a sampled
world. This is the discretized triggering-set representation of random LT:
each incoming edge is selected with its weight divided by 256, and the empty
triggering set receives the remaining probability. The same sampled worlds
are reused in every round and for every candidate score.

In each world, a seed set activates the vertices reachable on selected directed
edges. A round's marginal score is the sum of newly reachable vertices across
the supplied worlds. The output is little-endian signed 64-bit words:

```text
[k, selected_node_0, marginal_sum_0, ..., selected_node_(k-1), marginal_sum_(k-1)]
```

For `k=0`, the output is `[0]`. The maximum output is 136 bytes and workspace
is bounded at 4,096 bytes. The workspace estimate assumes 64-bit slots for
fixed edge records (576 bytes), incoming sums (64), draws (512), parent maps
(512), and greedy/current/queue arrays (256), then reserves another 512 bytes
for bounded locals and alignment. Caller-owned input and output buffers are
excluded. Invalid input returns `-1`; null output or
insufficient capacity returns `-2`, without writes. Validation order is
recorded in `workload.json`.

The supplied draw tape defines a deterministic empirical objective. This
profile does not generate random values and makes no accuracy or approximation
claim for the true expected influence. The original random-LT greedy
approximation statement concerns the expected influence function, not this
finite replay.

## Source and distinctness

The chapter is Zaixin Lu and Weili Wu, “Influence Maximization,” *Encyclopedia
of Algorithms*, Chapter 710, pp. 985–987,
[DOI 10.1007/978-1-4939-2864-4_710](https://doi.org/10.1007/978-1-4939-2864-4_710).
The pinned locations are “Influence Diffusion” (`Sec9105`), “Problem
(Influence Maximization)” (`Sec9106`), “Activation Models” (`Sec9107`), and
“Key Results—Greedy Algorithm” (`Sec9108`, Fig. 1). The chapter notes that
exact random-LT influence evaluation is #P-hard, motivating the supplied
finite-world profile.

The triggering-set sampler follows the probability construction in Kempe,
Kleinberg, and Tardos, “Maximizing the Spread of Influence through a Social
Network,” Section 4.3, Theorem 4.6,
[DOI 10.4086/toc.2015.v011a004](https://doi.org/10.4086/toc.2015.v011a004).
For random LT with total incoming weight at most one, each target independently
chooses at most one incoming parent with probability equal to that edge's
weight, or chooses none with the remaining probability.

The local [`influence_maximization_greedy_live_edge`](../influence_maximization_greedy_live_edge/README.md)
profile models independent-cascade worlds supplied as independent per-edge
masks. Such masks can encode a triggering world, but that package does not
sample mutually exclusive incoming parents from LT weights or accept an LT
draw tape. This profile includes that missing weight-to-trigger-world step;
it is not another mask-only reachability wrapper.

The ports and references are clean-room implementations of the mathematical
rules above. No source code, pseudocode, comments, fixtures, or article prose
is copied. See [`RIGHTS.md`](RIGHTS.md).

## Package files

- [`workload.json`](workload.json): bounded calls, fixtures, provenance, and
  workspace limits.
- [`primary_oracle.py`](primary_oracle.py): cumulative interval sampling and
  per-candidate queue traversals.
- [`independent_oracle.py`](independent_oracle.py): parent-map creation and
  transitive-closure scoring.
- [`INVENTORY.json`](INVENTORY.json), [`INVENTORY.md`](INVENTORY.md), and
  [`check_inventory.py`](check_inventory.py): static package inventory.

Ten language drafts are listed in the inventory. They are uncompiled and
unexecuted. Shared suite registration and global catalogs are coordinated
separately.
