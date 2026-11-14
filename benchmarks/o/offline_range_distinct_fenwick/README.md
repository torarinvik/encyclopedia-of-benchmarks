# Offline range-distinct counts by Fenwick sweep

This draft answers half-open range queries over a static integer array. Process
queries in nondecreasing right-endpoint order. As the right edge advances, keep
one marker at the latest position of each encountered value, removing its old
marker when it appears again. The sum of markers within a query's interval is
the number of distinct values in that interval. A Fenwick tree maintains the
markers. This sweep differs from the two-ended Mo ordering in
[`mos_algorithm`](../mos_algorithm/README.md), whose existing modes answer sum
and fixed-target frequency queries.

The scalar input is `[N,Q,values[N],(left,right)*Q]`, with `1<=N<=64`,
`0<=Q<=64`, values in `0..255`, and `0<=left<=right<=N`. Query intervals are
half-open, so empty intervals return zero. Return the sum of each distinct
count weighted by its one-based input query index. The largest possible result
is 133120. Invalid or null input returns `-1`; exact input length is
`2+N+2*Q`, at most 194 words, with 195 as the maximum parseable malformed
length. A zero-query input returns zero.

The reference sweep sorts queries by right endpoint. All ten language drafts
instead bucket queries by their bounded integer right endpoint, retaining
the input index for result weighting. Their sweep uses
`O(N+Q+(N+Q) log N)` time and `O(N+Q+256)` space. The sweep and direct-set
reference drafts are independent of each other. The workload, rights note,
package checker, and scalar runner/verifier registration are present. The
verifier source specifies small exhaustive inputs, reversed query order,
bijective value renaming, maximum frames, and null inputs. The workload includes a maximum-length frame with 64 full-range
queries over distinct values. Nothing has been compiled or run.

The [Library Checker task](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/static_range_count_distinct/task.md)
identifies the operation. The [AtCoder editorial](https://atcoder.jp/contests/awc0122/editorial/22807?lang=ja)
describes the sweep. Only algorithmic ideas are used; the contract, code, and
eventual fixtures are independently authored.
