# Linear-time Prüfer decoding

Decode a Prüfer sequence using the largest available leaf at each step, the
same label convention as [`prufer_code`](../prufer_code/README.md). The input
is `[n,code[0..n-3]]`, with `2 <= n <= 4096`, `0 <= code[i] < n`, and exact
length `n-1`; at most 4096 input words are parseable. Invalid or null input
returns `-1`. A valid input with null or short output returns `-2`, without
writing. Success emits `n-1` ordered pairs of little-endian signed i64 labels,
each pair `(leaf, code_value)` in removal order followed by the final edge;
the return is `16*(n-1)` bytes. The maximum output is 65520 bytes.

Count the remaining occurrences of each label. An absent label is a leaf.
Keep a monotonically decreasing scan cursor for the largest not-yet-scanned
leaf and a current leaf, which may instead be a newly exposed larger label.
After each removal, decrement the corresponding code label's count: if it
becomes zero above the cursor it is the next leaf; otherwise advance the
cursor downward to the next zero count. Mark removed leaves so the cursor
cannot select them again. The cursor traverses the labels at most once, so
decoding takes `O(n)` time and space, including output generation.
The cursor invariant is that no unconsumed leaf lies above it, except possibly
the current leaf newly exposed by the preceding
code value. At least two vertices remain after each code value, so the next
leaf exists; after the last value, the two remaining labels form the final edge.

This benchmark retains a separate method from the existing `prufer_code`
decoder, whose Rust and Mojo drafts search the active labels from scratch for
each leaf and sort the final edge list. The emitted edge order here is removal
order so output normalization does not dominate the linear kernel. The
[CP-Algorithms Prüfer article](https://cp-algorithms.com/graph/pruefer_code.html)
describes the monotone-cursor idea for the opposite leaf convention; this
profile independently adapts the method to largest-leaf decoding. Only
algorithmic ideas are used; no source prose, code, or examples are copied.

The contract, reference models, ten language drafts, workload, rights note,
package checker, and byte-output suite wiring are drafted. The verifier source
specifies exhaustive small sequences, full-size inputs, and buffer/error
probes. The timed workload includes 256-vertex star and path outputs in
addition to small boundary cases. No programs or checks have been executed;
all remain unverified.
