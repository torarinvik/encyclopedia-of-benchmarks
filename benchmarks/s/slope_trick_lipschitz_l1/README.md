# Slope-trick bounded-change L1 fitting

Given observations `a[0..n)`, minimize `sum(abs(a[i]-b[i]))` over integer
sequences satisfying `abs(b[i]-b[i-1]) <= h`. The heap-based slope-trick
method keeps the breakpoints of the convex cost in two heaps, lazily expands
their positions by `h`, and incorporates each new absolute-value term.

The `i64_array_scalar` frame is `[n,h,a...]`, with `0<=n<=128`, `0<=h<=100`,
and `0<=a[i]<=100`. It must have exactly `n+2` words. Return the minimum cost,
or `-1` for malformed or null input. The empty sequence costs zero. Maximum
valid/parseable lengths are 130/131; the result is at most 12800. The target
method runs in O(n log n) time and O(n) space. The independent bounded-domain
oracle uses direct dynamic programming: clipping any feasible fitted value to
`[0,100]` preserves the adjacent bound and cannot increase its error.
The measured workload includes a 32-observation alternating sequence to
exercise repeated breakpoint rebalancing. [Implementation notes](IMPLEMENTATION_NOTES.md)
record heap invariants and the fixture's cost bound.

No matching slope-trick or bounded-change L1 profile appeared in static
README and inventory searches. Median and isotonic profiles do not maintain
the two-sided adjacent-change constraint. [OI Wiki's slope-trick overview](https://oi-wiki.org/dp/opt/slope-trick/)
is used for the method; no code, text, or examples are copied.

Reserved for root. All ten language drafts, workload, independent
dynamic-programming oracle, and scalar-suite registration are present but
unverified. The verifier drafts exhaustive small and maximum-size cases.
The Elisa draft uses a bounded input view after its ABI null and length checks.
Nothing has been compiled or run.
