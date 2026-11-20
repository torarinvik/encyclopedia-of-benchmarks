# Maximum-weight unit-job schedule with release times

Given unit-duration jobs, choose a maximum-total-weight subset and assign each
chosen job to one integer slot within its inclusive release/deadline window.
The scalar input is `[n, (release, deadline, weight)*n]`: `0 <= n <= 32`,
`0 <= release <= deadline < 32`, and `0 <= weight <= 1000000`. The exact
length is `1 + 3*n`; at most 98 words can be parsed. Return the maximum total
weight, or `-1` for null or malformed input. The maximum result is 32000000.

The drafts process jobs in nonincreasing weight and maintain a matching between
accepted jobs and slots. An augmenting path can reassign previously accepted
jobs to make room. Matchable job sets form a transversal matroid, so the greedy
independence test yields a maximum-weight set. At most 32 searches inspect
32 jobs and 32 slots each, for O(n²s + n²) time with `s=32` slots. Shared
arrays and recursion need O(n+s) auxiliary space; implementations that copy
window arrays at each recursive call can use O(n²+s) space. This differs from the existing
[`job_scheduling_with_deadline`](../../j/job_scheduling_with_deadline/README.md)
heuristic, which never moves an already scheduled job.

The algorithm is based on the unit-job scheduling and matching relationship
described by [Dekel and Sahni](https://www.cise.ufl.edu/~sahni/papers/convexBipartite.pdf).
Only the mathematical idea is used; the implementation is independently
authored. Ten language drafts, an independent min-cost-flow reference, workload,
and rights note are present. Scalar runner and verifier wiring has been drafted;
the verifier specifies exhaustive three-slot cases and generated small cases
checked against a subset-and-slot reference, plus maximum-size and long
alternating-path frames. The workload also specifies a full 97-word frame with
one job per slot and null input at the parseable-length bound. Generated cases
also specify invariance under reversing job order and translating all slot
windows by the same offset within the allowed range.
No source has been compiled or run.
