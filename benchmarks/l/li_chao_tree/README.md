# Online Li Chao tree minimum queries

This benchmark maintains the lower envelope of lines `y = slope*x + intercept` as lines arrive and answers minimum-value queries at individual integer coordinates. Each pair of lines intersects at most once, so an insertion can keep the line that wins at a segment midpoint and send the other line down only the side where it can still win.

## Contract

- Input is `[operation_count, (opcode, first, second)...]`; every operation uses exactly three signed 64-bit values.
- There are 0–512 operations. The maximum parseable and valid input length is 1,537 values.
- Opcode `0` inserts line `y = slope*x + intercept`, where both coefficients are in `[-1000, 1000]`.
- Opcode `1` queries the minimum at `x = first`, which must be in `[-1,000,000, 1,000,000]`; its third field must be zero. A query requires at least one earlier inserted line.
- Unknown opcodes, malformed lengths, out-of-range values, or queries before the first insertion return `-1`. A null input pointer with positive length also returns `-1`.
- The result is `Σ(q * (minimum_at_query_q + 1,000,001,001))`, where `q` is the one-based query order. A trace with no queries returns zero.

The coefficient and coordinate limits keep every line value, checksum term, and total inside signed 64-bit arithmetic. Each insertion follows one root-to-leaf path in the coordinate interval, and each query compares the stored lines on its root-to-coordinate path. Both operations take `O(log U)` time, where `U = 2,000,001` is the number of integer coordinates. The tree uses `O(I log U)` nodes for `I` inserted lines; ports reserve `O(MAX_OPERATIONS log U)` node slots.

[`workload.json`](workload.json) covers crossing and parallel lines, both domain edges, repeated queries, checksum boundary values, empty traces, malformed operations, and the null-input case. [`benchmarks/li_chao_tree_oracle.py`](../../li_chao_tree_oracle.py) computes each query by scanning all earlier lines, independently of the tree structure. [`benchmarks/verify_li_chao_tree.py`](../../verify_li_chao_tree.py) statically checks the workload, oracle results, provenance, and presence of all nine source files; it does not compile or run the ports.

## Algorithm references

- [CP-Algorithms: Convex hull trick and Li Chao tree](https://cp-algorithms.com/geometry/convex_hull_trick.html) describes the midpoint comparison and the logarithmic insertion/query approach used as the algorithm basis. These implementations were written independently and do not copy its code.
- [Library Checker: Line Add Get Min](https://judge.yosupo.jp/problem/line_add_get_min) provides the task taxonomy for online line insertion and minimum-at-point queries. This benchmark defines its own bounded packed-array ABI and checksum workload.

## Implementations

The nine ports use the shared `i64_array_scalar` ABI. Their source files are under the `l` directory of `c`, `c3`, `cpp`, `elisa`, `nim`, `odin`, `rust`, `v`, and `zig`.
