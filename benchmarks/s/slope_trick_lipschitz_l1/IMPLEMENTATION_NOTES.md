# Heap invariants and bounds

After each observation, the left and right heaps represent breakpoints of a
convex piecewise-linear cost. In the fixed-array drafts both are max-heaps:
the left stores `breakpoint-shift_l`, while the right stores
`shift_r-breakpoint`. Their effective extrema
are `left[0]+shift_l` and `shift_r-right[0]`. Expanding the previous allowed
interval subtracts `h` from the left shift and adds `h` to the right shift.

Adding `abs(x-a)` inserts `a` into both breakpoint sets. If the effective
left maximum exceeds the right minimum, exchanging these extrema restores
their order and adds their difference to the minimum cost. For this update at
most one exchange is required. In the fixed-array ports the replacement keys
are no larger than the old heap roots, so a sift-down is sufficient. The C++
and Rust ports instead use standard priority queues.

The contract permits 128 insertions into each heap. The magnitude of either
lazy shift is at most 12800, so stored keys and their differences fit i64 by a
wide margin. Choosing the constant fitted sequence zero gives cost at most
12800, bounding the result. The 32-item alternating workload has a lower bound
of `16*(100-10)`: each disjoint adjacent pair must pay at least 90. Alternating
fitted values 0 and 10 attains that bound. These are static arguments; no
implementation, fixture, or checker has been run.
