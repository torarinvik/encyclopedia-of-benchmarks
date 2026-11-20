# Shortest subarray with sum at least K

This profile returns the length of the shortest nonempty contiguous segment
whose signed sum reaches a supplied threshold. Negative values are supported;
the empty segment is never a candidate.

## Contract

The ABI is i64_array_scalar, with exported symbol
shortest_subarray_with_sum_at_least_k. Input is
[target, count, value_0, ..., value_(count-1)].

- target is in [-4096,4096]; count is in [0,256].
- Each value is in [-1000,1000]; the exact input length is count+2.
- The maximum valid and parseable input lengths are 258 and 259 i64 words.
- Return the minimum nonempty qualifying length, or 0 when there is no
  qualifying segment (including a valid empty sequence). Invalid or
  out-of-profile input returns -1.

## Method and distinction

The primary builds prefix sums and scans them once with a monotone deque of
candidate prefix indices. It removes front candidates once they form a
qualifying segment, then removes dominated suffix prefixes before inserting
the current index. Every prefix index enters and leaves the deque at most
once, giving O(n) time and O(n) auxiliary space. The independent reference
enumerates every start/end pair in O(n^2) time.

This differs from local [minimum_size_subarray_sum](../../m/minimum_size_subarray_sum/README.md),
whose positive-only
sliding-window invariant does not hold for negative values. It also differs
from [max_sum_length_bounded_segment](../../m/max_sum_length_bounded_segment/README.md),
which maximizes sum subject
to length bounds rather than minimizing length subject to a sum threshold.

Chen and Chao present a linear-time algorithm for the shortest
sum-constrained segment in “Optimal algorithms for locating the longest and
shortest segments satisfying a sum or an average constraint”
([DOI](https://doi.org/10.1016/j.ipl.2005.08.006)). The
[LeetCode title page](https://leetcode.com/problems/shortest-subarray-with-sum-at-least-k/) was
used only to discover the benchmark profile; no problem text, examples,
tests, editorials, or code were reused. The local sentinel conventions and
bounded input profile are repository-specific.

The workload includes negative-target cases, cases requiring negative
elements, no-solution and empty inputs, both input-length boundaries, and
malformed frames. See workload.json, the two references, and RIGHTS.md.

| Language | Source |
|---|---|
| C | [c/s/shortest_subarray_with_sum_at_least_k.c](../../../c/s/shortest_subarray_with_sum_at_least_k.c) |
| C3 | [c3/s/shortest_subarray_with_sum_at_least_k.c3](../../../c3/s/shortest_subarray_with_sum_at_least_k.c3) |
| C++ | [cpp/s/shortest_subarray_with_sum_at_least_k.cpp](../../../cpp/s/shortest_subarray_with_sum_at_least_k.cpp) |
| Elisa | [elisa/s/shortest_subarray_with_sum_at_least_k.elisa](../../../elisa/s/shortest_subarray_with_sum_at_least_k.elisa) |
| Mojo | [mojo/s/shortest_subarray_with_sum_at_least_k.mojo](../../../mojo/s/shortest_subarray_with_sum_at_least_k.mojo) |
| Nim | [nim/s/shortest_subarray_with_sum_at_least_k.nim](../../../nim/s/shortest_subarray_with_sum_at_least_k.nim) |
| Odin | [odin/s/shortest_subarray_with_sum_at_least_k.odin](../../../odin/s/shortest_subarray_with_sum_at_least_k.odin) |
| Rust | [rust/s/shortest_subarray_with_sum_at_least_k.rs](../../../rust/s/shortest_subarray_with_sum_at_least_k.rs) |
| V | [v/s/shortest_subarray_with_sum_at_least_k.v](../../../v/s/shortest_subarray_with_sum_at_least_k.v) |
| Zig | [zig/s/shortest_subarray_with_sum_at_least_k.zig](../../../zig/s/shortest_subarray_with_sum_at_least_k.zig) |
