# k-means++ D² seeding

This package benchmarks the center-seeding stage of k-means++. It chooses a
first data row explicitly, then chooses each later row in proportion to its
squared Euclidean distance from the closest selected center. The weighted
choices use an input tape of exact integer draws, making the randomized method
deterministic and replayable without including a PRNG in the measured routine.

## Contract

- ABI: `int64_t kmeans_plus_plus_seeding(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity)` (`i64_array_bytes_output`).
- Input is `[point_count, dimension, k, first_row, coordinates..., draws...]`.
  There are 1–32 points, 1–4 dimensions, `1 <= k <= min(8, point_count)`,
  and `first_row` is a zero-based row index. Coordinates are row-major integers
  in `[-16,16]`. The frame contains exactly `4 + point_count*dimension + k-1`
  signed 64-bit words; the parser accepts up to 140 words to reject a trailing
  word after the maximum valid frame of 139 words.
- The first center is the data row at `first_row`. For each later center,
  compute each row's squared Euclidean distance to its nearest selected center.
  Sum those integer weights in ascending row order. The corresponding tape
  value is an integer `r` in `[0,total_weight)`. Scan rows in ascending order
  and choose the first row whose cumulative weight is strictly greater than
  `r`. Thus row `i` receives exactly `D_i^2` draw slots. All arithmetic is
  exact; the maximum total weight is 131072.
- A selected row and every duplicate row at the same coordinates have zero
  weight. Duplicate rows remain separate candidates, so their multiplicity is
  represented when they have positive weight. If all weights sum to zero,
  the tape value for that step must be zero and the selected row is the
  lowest-index row not already selected. This fallback completes `k` distinct
  row indices even when all points are duplicates or `k` exceeds the number of
  unique coordinates.
- Output is the selected zero-based row indices in selection order, as
  little-endian signed 64-bit integers. It is `8*k` bytes, at most 64. Invalid
  frames, coordinates, or draw tapes return `-1`; null output or insufficient
  capacity returns `-2` without writes. Input and all draw values are validated
  before output storage is checked.

## Relationship to local k-means benchmarks

The local [`k_means_clust`](../k_means_clust/README.md),
[`kmeans_rust`](../kmeans_rust/README.md), and
[`kmeans_raw_r`](../kmeans_raw_r/README.md) packages cover Lloyd assignment and
centroid updates with caller-supplied, fixed, or externally chosen initial
rows. They do not implement D² weighted seeding. This package measures that
initialization rule and returns the chosen row indices without running Lloyd
iterations.

## Workload and references

[`workload.json`](workload.json) covers cumulative-weight boundaries, multiple
dimensions, duplicate rows, zero-total fallback, invalid tapes, malformed
frames, and output errors. The primary reference maintains each point's
nearest-center distance incrementally. The independent reference recomputes
all distances to all selected centers on every selection and uses a prefix
array with binary search for the weighted draw.

Arthur and Vassilvitskii's [SODA 2007 paper](https://theory.stanford.edu/~sergei/papers/kMeansPP-soda.pdf)
introduces the method: choose the first center uniformly from the data, then
choose each later center with probability proportional to its squared distance
from the closest already chosen center. The [Google Research publication
record](https://research.google/pubs/k-means-the-advantages-of-careful-seeding/)
records the paper's authors and proceedings citation. The [RosettaGit public
task-title index](https://rosettagit.org/tasks/) was used only to discover the
title “K-means++ clustering.” The deterministic tape and bounds are this
benchmark's profile; no task text, examples, tests, submissions, or code were
used.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/k/kmeans_plus_plus_seeding.c`](../../../c/k/kmeans_plus_plus_seeding.c) |
| C3 | [`c3/k/kmeans_plus_plus_seeding.c3`](../../../c3/k/kmeans_plus_plus_seeding.c3) |
| C++ | [`cpp/k/kmeans_plus_plus_seeding.cpp`](../../../cpp/k/kmeans_plus_plus_seeding.cpp) |
| Elisa | [`elisa/k/kmeans_plus_plus_seeding.elisa`](../../../elisa/k/kmeans_plus_plus_seeding.elisa) |
| Mojo | [`mojo/k/kmeans_plus_plus_seeding.mojo`](../../../mojo/k/kmeans_plus_plus_seeding.mojo) |
| Nim | [`nim/k/kmeans_plus_plus_seeding.nim`](../../../nim/k/kmeans_plus_plus_seeding.nim) |
| Odin | [`odin/k/kmeans_plus_plus_seeding.odin`](../../../odin/k/kmeans_plus_plus_seeding.odin) |
| Rust | [`rust/k/kmeans_plus_plus_seeding.rs`](../../../rust/k/kmeans_plus_plus_seeding.rs) |
| V | [`v/k/kmeans_plus_plus_seeding.v`](../../../v/k/kmeans_plus_plus_seeding.v) |
| Zig | [`zig/k/kmeans_plus_plus_seeding.zig`](../../../zig/k/kmeans_plus_plus_seeding.zig) |
