# Binary-search maximum-average segment

This profile returns the maximum average of a contiguous subarray whose
length is at least a caller-supplied minimum, quantized downward to thousandths.
Its primary kernel binary-searches that integer threshold and checks
feasibility with transformed prefix sums.

## Contract

The `i64_array_scalar` input is `[n,L,value_0,...,value_(n-1)]`.
`1 <= n <= 32`, `1 <= L <= n`, and each value lies in `[-1000,1000]`.
The frame must contain exactly `n+2` signed 64-bit values. At most 35 words
are parsed so trailing data can be rejected; the largest valid frame is 34
words. A valid call returns `floor(1000 * maximum_average)`, in
`[-1000000,1000000]`. Null input, malformed framing, or values outside the
profile return `-1000001`, which is outside the valid result range.

For a candidate integer threshold `q`, transform each value `a[i]` to
`1000*a[i]-q`. An original interval has average at least `q/1000` exactly
when its transformed sum is nonnegative. Prefix sums make the feasibility
check linear: at each end position, compare its prefix against the smallest
prefix whose start is at least `L` positions earlier. Binary search finds the
largest feasible `q`. The primary takes `O(n log 2,000,001)` time and `O(n)`
workspace. The independent oracle enumerates all allowed intervals and uses
cross multiplication, without threshold search or transformed prefixes.

This differs from [`max_average_length_bounded_segment`](../../m/max_average_length_bounded_segment/README.md),
which scans a caller-specified closed interval of lengths and returns an exact
ratio and witness. This package searches one minimum-length constraint and
returns a fixed-point scalar using the CP-Algorithms transformed-prefix
feasibility method.

## Sources and artifacts

Primary source: [CP-Algorithms, “Maximum average segment”](https://cp-algorithms.com/others/maximum_average_segment.html), section “Search for a subarray with a maximum/minimum average.” The source idea is adapted clean-room to a bounded integer profile. See [`RIGHTS.md`](RIGHTS.md).

The hand-derived fixtures are in [`workload.json`](workload.json). The primary
reference is [`primary_oracle.py`](primary_oracle.py); the independent exact
enumerator is [`independent_oracle.py`](independent_oracle.py). Static source
and workload inventories are provided by [`verify_workload.py`](verify_workload.py)
and [`check_inventory.py`](check_inventory.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/b/binary_search_maximum_average_segment.c`](../../../c/b/binary_search_maximum_average_segment.c) |
| C3 | [`c3/b/binary_search_maximum_average_segment.c3`](../../../c3/b/binary_search_maximum_average_segment.c3) |
| C++ | [`cpp/b/binary_search_maximum_average_segment.cpp`](../../../cpp/b/binary_search_maximum_average_segment.cpp) |
| Elisa | [`elisa/b/binary_search_maximum_average_segment.elisa`](../../../elisa/b/binary_search_maximum_average_segment.elisa) |
| Mojo | [`mojo/b/binary_search_maximum_average_segment.mojo`](../../../mojo/b/binary_search_maximum_average_segment.mojo) |
| Nim | [`nim/b/binary_search_maximum_average_segment.nim`](../../../nim/b/binary_search_maximum_average_segment.nim) |
| Odin | [`odin/b/binary_search_maximum_average_segment.odin`](../../../odin/b/binary_search_maximum_average_segment.odin) |
| Rust | [`rust/b/binary_search_maximum_average_segment.rs`](../../../rust/b/binary_search_maximum_average_segment.rs) |
| V | [`v/b/binary_search_maximum_average_segment.v`](../../../v/b/binary_search_maximum_average_segment.v) |
| Zig | [`zig/b/binary_search_maximum_average_segment.zig`](../../../zig/b/binary_search_maximum_average_segment.zig) |

No programs, tests, scripts, checkers, builds, compilers, benchmarks, or
profilers were run while preparing this package.
