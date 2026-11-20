# K-ary Huffman weighted path cost

This profile measures the weighted external path length of a full nonbinary
Huffman tree. The allowed arities are three and four, so the emitted code
symbols are k-ary digits; the local binary Huffman and length-limited binary
package-merge profiles use a different alphabet and tree arity.

## Contract

The `i64_array_scalar` input is `[k,n,w0,...,w(n-1)]`. Arity `k` is 3 or 4,
`1<=n<=10`, and weights are in `0..1000`. A one-symbol input is valid and
has cost zero. For `n>1`, the full-tree condition `(n-1) mod (k-1)=0` must
hold. Other symbol counts are malformed. Restricting the domain this way
avoids defining or inserting padding leaves. The valid frame is exactly
`n+2` signed-i64 values; one additional parseable word is rejected.

At each step the primary repeatedly removes the k active trees with the
smallest `(weight, insertion_id)` pair, creates a parent whose weight is
their sum, and adds that parent weight to the result. This sum equals
`sum(weight_i * code_length_i)` for the resulting tree. The returned scalar
is in `0..90000`; malformed input returns `-1`.

The maximum valid/parseable input lengths are 12/13 words. Fixed workspace is
capped at 1024 bytes. The primary takes O(n²) time by scanning the active
root array at each merge and O(n) auxiliary space. The independent reference
enumerates every full ordered k-ary tree shape, sorts the input weights from
largest to smallest and leaf depths from shallowest to deepest, then selects
the minimum weighted cost. For this bound it examines at most 55 ternary
shapes or 22 quaternary shapes; its auxiliary space is O(S*n) when retaining
the bounded shape list, where S is the number of full tree shapes.

NIST DADS explicitly lists k-ary Huffman coding as a Huffman specialization
and describes joining k least-weight trees into a k-ary tree, with one
k-symbol code digit per level. The binary Huffman method is attributed to
Huffman’s 1952 paper. This benchmark uses the DADS operation definition on
full-tree-compatible counts only; it does not implement the general padding
extension.

See [`workload.json`](workload.json), [`primary_oracle.py`](primary_oracle.py),
[`independent_oracle.py`](independent_oracle.py), [`RIGHTS.md`](RIGHTS.md),
and [`INVENTORY.json`](INVENTORY.json). The shared `i64_array_scalar` runner
and verifier and the catalog now register this package. All ten language
paths are listed below.

| Language | Source |
| --- | --- |
| C | [`c/k/k_ary_huffman_weighted_path_cost.c`](../../../c/k/k_ary_huffman_weighted_path_cost.c) |
| C3 | [`c3/k/k_ary_huffman_weighted_path_cost.c3`](../../../c3/k/k_ary_huffman_weighted_path_cost.c3) |
| C++ | [`cpp/k/k_ary_huffman_weighted_path_cost.cpp`](../../../cpp/k/k_ary_huffman_weighted_path_cost.cpp) |
| Elisa | [`elisa/k/k_ary_huffman_weighted_path_cost.elisa`](../../../elisa/k/k_ary_huffman_weighted_path_cost.elisa) |
| Mojo | [`mojo/k/k_ary_huffman_weighted_path_cost.mojo`](../../../mojo/k/k_ary_huffman_weighted_path_cost.mojo) |
| Nim | [`nim/k/k_ary_huffman_weighted_path_cost.nim`](../../../nim/k/k_ary_huffman_weighted_path_cost.nim) |
| Odin | [`odin/k/k_ary_huffman_weighted_path_cost.odin`](../../../odin/k/k_ary_huffman_weighted_path_cost.odin) |
| Rust | [`rust/k/k_ary_huffman_weighted_path_cost.rs`](../../../rust/k/k_ary_huffman_weighted_path_cost.rs) |
| V | [`v/k/k_ary_huffman_weighted_path_cost.v`](../../../v/k/k_ary_huffman_weighted_path_cost.v) |
| Zig | [`zig/k/k_ary_huffman_weighted_path_cost.zig`](../../../zig/k/k_ary_huffman_weighted_path_cost.zig) |

No program, test, script, checker, build, compiler, profiler, or benchmark was
run.
