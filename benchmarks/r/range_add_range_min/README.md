# Range addition and minimum queries

This draft maintains an integer array with lazy range addition and half-open
range-minimum queries. [`lazy_segment_tree_range_add_sum`](../../l/lazy_segment_tree_range_add_sum/README.md)
stores sums instead of minima; [`range_linear_add_range_min`](../range_linear_add_range_min/README.md)
supports index-dependent additions using block hulls rather than a lazy
minimum segment tree.

The `i64_array_bytes_output` input is `[n,q,values[n],(op,l,r,delta)[q]]`,
with `1 <= n,q <= 64`, initial values in `[-1000000,1000000]`, and nonempty
half-open ranges. Operation 0 adds a delta in `[-100000,100000]`; operation 1
returns the minimum and requires delta zero. At least one query is required.
The output is one little-endian i64 per query, at most 512 bytes. Invalid or
null input returns `-1`; null or short output returns `-2`, with no writes on
error. Maximum valid input length is 322 words.

The bounded primary keeps a minimum and pending-addition tag at each node of
a fixed segment tree. It uses O(n) build time, O(log n) per operation, and
O(n) working storage. The independent reference updates and queries a flat
array directly.

The [Library Checker task](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/data_structure/range_add_range_min/task.md)
provides the operation idea; its repository declares Apache-2.0. The contract,
code, and reference are independently written without copying task text,
implementations, or fixtures.

Status: drafts in all ten supported languages, a direct reference, workload,
and suite registration are present. Nothing has been compiled or run.
