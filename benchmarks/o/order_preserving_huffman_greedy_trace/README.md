# Greedy order-preserving Huffman trace

This bounded profile constructs the ordered binary merge tree described by
NIST DADS for order-preserving Huffman coding. At each step it merges the
adjacent pair of active trees with the smallest combined weight. A tie is
resolved by choosing the leftmost pair; this tie rule is a deterministic
choice made for this benchmark profile because the source description does
not specify ties. The output reports each original symbol's tree depth and
the resulting weighted path cost.

The profile preserves input symbol order, but it is not unrestricted Huffman
coding and does not claim an optimal alphabetic prefix code. DADS expressly
distinguishes this adjacent-pair heuristic from true Huffman coding and notes
that optimum order-preserving coding uses other, more complicated methods.
The local [`garsia_wachs_alphabetic_tree`](../../g/garsia_wachs_alphabetic_tree/README.md)
package implements that different optimal method.

## Input and output

The exported symbol is `order_preserving_huffman_greedy_trace` with the
`i64_array_bytes_output` ABI:

```text
input  = [n, weight_0, ..., weight_(n-1)]
output = [n, weighted_path_cost, depth_0, ..., depth_(n-1)]
```

The input has exactly `n+1` signed 64-bit words, `2 <= n <= 8`, and every
weight is in `1..=15`. Thus the maximum valid and parseable frame lengths are
9 and 10 words. Output words are signed 64-bit little-endian. A successful
call returns `8*(n+2)` bytes, at most 80. Invalid or malformed input returns
`-1`; a null output or insufficient capacity returns `-2`, after the input
has been validated. Implementations stage output before writing, so an error
does not modify the output buffer.

The total weight is at most 120, each depth is at most 7, and weighted cost
is at most 840. The fixed workspace cap is 2,048 bytes, including merge-tree
nodes or interval blocks, depth/output staging, and traversal scratch.

## References and bounds

The primary reference explicitly stores the ordered merge tree and traverses
it to recover leaf depths. The independent reference stores only each active
component's contiguous leaf interval and total weight; at every merge it
increments the depths of leaves in the two selected intervals. Both choose
the same leftmost minimum pair, but use different internal representations.
Each takes `O(n^2)` time and `O(n)` bounded storage in this profile.

The method source is NIST DADS, [“order-preserving Huffman coding”](https://xlinux.nist.gov/dads/HTML/orderPreservingHuffmanCoding.html).
The page describes the adjacent-minimum merge and notes that it may differ
from true Huffman coding. It cites Graefe, “Implementing Sorting in Database
Systems,” [DOI 10.1145/1132960.1132964](https://doi.org/10.1145/1132960.1132964),
for context. The implementation uses the algorithm description only; no
source code, task text, examples, or tests are reused. See [RIGHTS.md](RIGHTS.md).

## Ports and fixed workload

| Language | Source |
|---|---|
| C | [`c/o/order_preserving_huffman_greedy_trace.c`](../../../c/o/order_preserving_huffman_greedy_trace.c) |
| C3 | [`c3/o/order_preserving_huffman_greedy_trace.c3`](../../../c3/o/order_preserving_huffman_greedy_trace.c3) |
| C++ | [`cpp/o/order_preserving_huffman_greedy_trace.cpp`](../../../cpp/o/order_preserving_huffman_greedy_trace.cpp) |
| Elisa | [`elisa/o/order_preserving_huffman_greedy_trace.elisa`](../../../elisa/o/order_preserving_huffman_greedy_trace.elisa) |
| Mojo | [`mojo/o/order_preserving_huffman_greedy_trace.mojo`](../../../mojo/o/order_preserving_huffman_greedy_trace.mojo) |
| Nim | [`nim/o/order_preserving_huffman_greedy_trace.nim`](../../../nim/o/order_preserving_huffman_greedy_trace.nim) |
| Odin | [`odin/o/order_preserving_huffman_greedy_trace.odin`](../../../odin/o/order_preserving_huffman_greedy_trace.odin) |
| Rust | [`rust/o/order_preserving_huffman_greedy_trace.rs`](../../../rust/o/order_preserving_huffman_greedy_trace.rs) |
| V | [`v/o/order_preserving_huffman_greedy_trace.v`](../../../v/o/order_preserving_huffman_greedy_trace.v) |
| Zig | [`zig/o/order_preserving_huffman_greedy_trace.zig`](../../../zig/o/order_preserving_huffman_greedy_trace.zig) |

The fixed cases are in [`workload.json`](workload.json). The independent
references are [`primary_oracle.py`](primary_oracle.py) and
[`independent_oracle.py`](independent_oracle.py). [`check_inventory.py`](check_inventory.py)
and [`verify_workload.py`](verify_workload.py) expose static package/workload
checks. The package is registered in the `i64_array_bytes_output` runner and
verifier. These checks have not been run.
