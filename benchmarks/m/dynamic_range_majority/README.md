# Dynamic range majority

This draft maintains an array under point assignments and finds a strict
majority in a requested half-open subrange. A segment tree combines
Boyer–Moore cancellation summaries to nominate a candidate; a value-indexed
position bitmap then verifies its frequency. The existing
[`boyer_moore_majority_vote`](../../b/boyer_moore_majority_vote/README.md)
only handles a static whole array, while
[`point_set_range_frequency`](../../p/point_set_range_frequency/README.md)
counts a supplied value without choosing a majority candidate.

The proposed `i64_array_bytes_output` input is `[n,q,values[n],(op,a,b)[q]]`.
For `op=0`, assign value `b` at index `a`; for `op=1`, query `[a,b)`.
Array length and operation count are each 1–64, values are in
`0..1,000,000,000`, and query ranges must be nonempty. At least one query is
required. Each query emits one little-endian i64: its majority value or `-1`.
Invalid input returns `-1`; null or short output returns `-2` without writes.
The maximum valid frame has 258 i64 words and the maximum output is 512 bytes.

The bounded C draft uses at most 128 distinct value slots and a 64-bit bitmap
per value. With `d` distinct values seen so far, updates cost O(d + log n),
queries O(d + log n), and storage O(n + d); bitmap population counting is
bounded by 64 bit operations. A direct frequency-count model is provided for
independent comparison.

The [Library Checker task](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/data_structure/majority_voting/task.md)
supplies the operation idea; its repository declares Apache-2.0. The local
contract and implementation are independently written, without copying task
prose, code, or fixtures.

Status: all ten language drafts, a direct reference, a workload, and byte-output
suite registration are present. The verifier source specifies exhaustive
small arrays with updates, maximum-size, position-63, malformed-input, and
buffer cases. Nothing has been compiled or run.
