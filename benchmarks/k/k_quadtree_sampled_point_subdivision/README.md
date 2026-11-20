# Sampled point subdivision for a K-quadtree

This package isolates the endpoint-subdivision stage from Chapter 585's
K-quadtree construction. It receives the points directly, sorts them by
fixed-depth Morton order, samples ranks `0,k,2k,...`, and reports the
deduplicated canonical split squares induced by consecutive sampled points.
It does not implement edge-cell distribution or emit the paper's full list of
Z-interval endpoints.

## Contract

The exported function is
`k_quadtree_sampled_point_subdivision(input, length, output, capacity)` with
ABI `i64_array_bytes_output`. The input frame is
`[n,k,D,(x,y)*n]`: `1 <= n <= 32`, `1 <= k <= n`, `1 <= D <= 8`, and points
are unique integer coordinates in `[0,2^D) × [0,2^D)`. The exact valid frame
has `3+2n` words (maximum 67); 68 is the largest parseable frame and permits
rejecting one extra word. Malformed input returns `-1` before output checks.
A null output or insufficient capacity returns `-2`, without writing bytes.

Morton digits are read from the most significant coordinate bit to the least
significant. A digit is `2*x_bit + y_bit`, giving the paper's quadrant order
SW, NW, SE, NE with y increasing upward. Let `s = floor((n-1)/k)+1` be the
sample count. For each adjacent sample pair, the smallest canonical square
containing both is their longest common quadrant-prefix. Equal squares are
deduplicated. A square is encoded as `(depth,prefix)`, where the root is
`(0,0)` and `prefix` is the integer represented by its `depth` base-4 digits
(leading zeroes are implicit). Descriptors are emitted in Morton preorder:
increasing interval start `prefix * 4^(D-depth)`, then increasing depth so a
square precedes descendants with the same start.

Output is `[r,(depth,prefix)*r]`, where `r` is the number of unique split
squares and `r <= s-1`. Each word is a signed 64-bit little-endian value; the
function returns the byte count. With `n=32`, `k=1`, `D=5`, and points
`(0,0)..(0,31)`, all 31 binary-prefix split squares are present, reaching the
504-byte output cap. A one-sample input emits only `[0]` (8 bytes).

Ports use bounded fixed arrays. Sorting, split deduplication, and preorder
normalization are implemented with bounded array scans; the stated runtime
for these ports is `O(n^2 + sD)` and workspace is capped at 4,096 bytes,
excluding caller input and output buffers. The paper's external-memory
complexity is not claimed for this in-memory ABI profile.

## References and duplicate rationale

The source is H. Haverkort, M. McGranaghan, and L. Toma, “An Edge Quadtree
for External Memory,” §2 and §3, especially the “Constructing the subdivision”
paragraph and Lemma 1, [SEA 2013 paper](https://doi.org/10.1007/978-3-642-38527-8_12)
([author-hosted PDF](https://tildesites.bowdoin.edu/~ltoma/papers/2013-sea-quad.pdf)).
The Encyclopedia crosswalk is [Chapter 585](https://doi.org/10.1007/978-1-4939-2864-4_585).
The paper selects every kth point in Z-order and splits at the smallest
canonical square containing each consecutive sample pair. This benchmark
serializes the resulting unique split-square set directly; the paper's later
edge-distribution phase is outside the contract.

This is distinct from the local [`quad_tree`](../quad_tree/README.md), which
builds an insertion-order point quadtree; [`morton_sort`](../../m/morton_sort/README.md),
which only orders points; and the PMR/Star quadtree profiles, which use other
stopping and subdivision rules. The independent oracle recursively partitions
the sampled Morton keys by quadrant instead of deriving splits from adjacent
pair LCAs.

The clean-room references are [`primary_oracle.py`](primary_oracle.py) and
[`independent_oracle.py`](independent_oracle.py). See [workload.json](workload.json),
[RIGHTS.md](RIGHTS.md), and [INVENTORY.md](INVENTORY.md). The ten ports and
static helpers are listed in the inventory. Workload cases pin their output as
signed-i64 word arrays; the package verifier packs those words to the ABI's
little-endian bytes. Shared `i64_array_bytes_output` runner/verifier and
catalog integration are complete. No executable checks have been run.
