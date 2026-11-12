# Segment History Extreme

Maintain a sequence under range assignment and range addition, answering both
current range-maximum queries and historical range-maximum queries. The
historical value at each position starts at its initial value and includes the
value after every update. A historical query returns the maximum of those
per-position histories within its range.

This package ports OI Wiki's CPU-monitoring variant of Segment History Extreme.
It is distinct from [`segment_tree_beats`](../segment_tree_beats/README.md),
which supports current-value range chmin/chmax/add and aggregate queries but
does not track values across time. This bounded profile uses range assignment
and addition and exposes current and historical maxima.

## Input and ABI

The exported C ABI symbol is
`segment_history_extreme(const int64_t *input, size_t input_length,
uint8_t *output, size_t output_capacity)` using
`i64_array_bytes_output`.

Input is `[N, Q, initial[N], operation[Q][4]]`. `N` is in `1..=32`, `Q` is in
`0..=32`, and initial values and update arguments are in `-1000..=1000`.
Operation records use zero-based half-open ranges `[left,right)`:

| Opcode | Record | Effect |
|---|---|---|
| 0 | `[0,left,right,value]` | Assign `value` to every position in the range. |
| 1 | `[1,left,right,delta]` | Add `delta` to every position in the range. |
| 2 | `[2,left,right,0]` | Append the current maximum on the range. |
| 3 | `[3,left,right,0]` | Append the maximum historical value on the range. |

Ranges must satisfy `0 <= left < right <= N`; query records must have argument
zero. There are exactly `2 + N + 4Q` signed 64-bit input words. Output is one
signed 64-bit little-endian word per query, in operation order, with at most
256 bytes. Success returns the byte count. Invalid input returns -1; null or
undersized output returns -2. The complete answer is staged before writing,
so errors leave output untouched. The workspace bound is 8,192 bytes.

The operation set and history timing follow the OI Wiki CPU-monitoring example:
the history includes the initial array and the array after every update. The
range convention is normalized to zero-based half-open intervals for this ABI.

## Algorithm and complexity

Each segment-tree node stores its current maximum and maximum historical value.
Lazy additions carry both a net offset and the largest prefix offset seen
while the tag is pending. A tag is propagated when either field is nonzero, so
a sequence whose net addition is zero still transfers its historical peak. If
an assignment has occurred since the node last pushed, the node also stores
the current assigned value and the largest value seen during that assignment
phase. Pushing additions before assignments preserves the source's tag order
and transfers each child's maximum history without replaying every element.
Updates and queries take O(log N) time, with O(N) tree storage for this bounded
profile.

The primary oracle simulates updates on current and history arrays. The
independent verifier recomputes each query by replaying the preceding update
prefix from the initial array. Both are bounded by N,Q <= 32.

## Sources and ports

The clean-room ports follow the algorithm description in OI Wiki's
[Segment History Extreme chapter](https://en.oi-wiki.org/ds/seg-beats/),
specifically its CPU-monitoring variant. The page is CC BY-SA 4.0 with SATA
terms; no source code or prose is copied. See [RIGHTS.md](RIGHTS.md).

| Language | Port |
|---|---|
| C | [`c/s/segment_history_extreme.c`](../../../c/s/segment_history_extreme.c) |
| C3 | [`c3/s/segment_history_extreme.c3`](../../../c3/s/segment_history_extreme.c3) |
| C++ | [`cpp/s/segment_history_extreme.cpp`](../../../cpp/s/segment_history_extreme.cpp) |
| Elisa | [`elisa/s/segment_history_extreme.elisa`](../../../elisa/s/segment_history_extreme.elisa) |
| Mojo | [`mojo/s/segment_history_extreme.mojo`](../../../mojo/s/segment_history_extreme.mojo) |
| Nim | [`nim/s/segment_history_extreme.nim`](../../../nim/s/segment_history_extreme.nim) |
| Odin | [`odin/s/segment_history_extreme.odin`](../../../odin/s/segment_history_extreme.odin) |
| Rust | [`rust/s/segment_history_extreme.rs`](../../../rust/s/segment_history_extreme.rs) |
| V | [`v/s/segment_history_extreme.v`](../../../v/s/segment_history_extreme.v) |
| Zig | [`zig/s/segment_history_extreme.zig`](../../../zig/s/segment_history_extreme.zig) |

The fixed fixtures are in [`workload.json`](workload.json). The primary and
independent oracle modules are
[`segment_history_extreme_oracle.py`](../../segment_history_extreme_oracle.py)
and
[`segment_history_extreme_verifier_oracle.py`](../../segment_history_extreme_verifier_oracle.py).
The shared byte-output suite registers the direct-array oracle, independent
prefix-replay verifier, bounds, full-output update profile, malformed records,
and capacity cases. The static checker and suite have not been run.
