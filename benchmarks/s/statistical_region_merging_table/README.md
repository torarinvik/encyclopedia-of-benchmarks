# Statistical region merging with supplied bounds (in progress)

This bounded grayscale profile follows the ordered region-merging structure
of statistical region merging. Each pixel starts as a region. Visit every
horizontal and vertical neighboring pixel pair, ordered by the absolute
difference of their original intensities, then by their row-major endpoint
indices. If their current regions differ, compare their current means using
the supplied size-dependent squared bounds and merge if the squared mean
difference is at most the sum of the two bounds. Output each pixel's smallest
row-major index in its final region as one byte.

The proposed `i64_array_bytes_output` input is `[height,width,bounds...,pixels...]`:
`1 <= height,width <= 6`, `n = height*width`, exactly `n` bounds for region
sizes 1 through n, then `n` grayscale bytes. Bounds are integers in
`0..65535`; pixels are integers in `0..255`. Input has exactly `2+2*n`
words. A merge of regions with sums `sa,sb` and sizes `a,b` occurs when
`(sa*b-sb*a)^2 <= (bounds[a-1]+bounds[b-1])*a^2*b^2`. This integer comparison
avoids rounding. The output is n bytes. Invalid input returns `-1`; a null or
short output returns `-2`, with no writes on either error.

The caller provides the squared statistical bounds: choosing a table derived
from the paper's formula gives its corresponding predicate; arbitrary tables
exercise the same ordered merge procedure but need not carry its statistical
guarantees. There is no smoothing, RGB predicate, small-region cleanup, or
second pass. The primary oracle sorts the O(n) grid edges and uses a
disjoint-set forest, for O(n log n) time and O(n) space. The C draft scans
the fixed 256 possible differences in order and uses a disjoint-set forest;
its fixed-intensity-range time is O(n α(n)) and auxiliary space is O(n).

Sources: Nock and Nielsen, [“Statistical Region Merging”](https://www.lix.polytechnique.fr/~nielsen/pdf/2004-StatisticalRegionMerging-PAMI.pdf),
and the [PARSEC technical report](https://www.cs.princeton.edu/techreports/2010/890.pdf),
which identifies this method in Ferret. The publications identify the method;
no source code, figures, prose or example data are reused.

**Status:** two oracle drafts, workload, ten language drafts and byte-output
suite registration are present. All remain unexecuted and need validation.
The workload includes exact-threshold and just-over-threshold merges; the
suite also defines generated comparisons between the two references and
checks that all listed source paths contain the exported symbol.

| Language | Draft |
| --- | --- |
| C | [`c/s/statistical_region_merging_table.c`](../../../c/s/statistical_region_merging_table.c) |
| C3 | [`c3/s/statistical_region_merging_table.c3`](../../../c3/s/statistical_region_merging_table.c3) |
| C++ | [`cpp/s/statistical_region_merging_table.cpp`](../../../cpp/s/statistical_region_merging_table.cpp) |
| Elisa | [`elisa/s/statistical_region_merging_table.elisa`](../../../elisa/s/statistical_region_merging_table.elisa) |
| Mojo | [`mojo/s/statistical_region_merging_table.mojo`](../../../mojo/s/statistical_region_merging_table.mojo) |
| Nim | [`nim/s/statistical_region_merging_table.nim`](../../../nim/s/statistical_region_merging_table.nim) |
| Odin | [`odin/s/statistical_region_merging_table.odin`](../../../odin/s/statistical_region_merging_table.odin) |
| Rust | [`rust/s/statistical_region_merging_table.rs`](../../../rust/s/statistical_region_merging_table.rs) |
| V | [`v/s/statistical_region_merging_table.v`](../../../v/s/statistical_region_merging_table.v) |
| Zig | [`zig/s/statistical_region_merging_table.zig`](../../../zig/s/statistical_region_merging_table.zig) |
