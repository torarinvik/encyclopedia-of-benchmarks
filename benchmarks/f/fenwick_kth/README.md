# Fenwick binary lifting for frequency selection

This package maintains nonnegative frequencies at fixed, ordered indices. It
supports point additions/removals and one-based selection of the index
containing a requested occurrence. The selection walks Fenwick prefix blocks
from the highest power of two downward; it does not binary-search indices by
repeated prefix queries.

## Contract

The scalar ABI and exported symbol are `i64_array_scalar` and `fenwick_kth`.
Input is `[n, q, frequency[0..n), operation_rows...]`, where each operation
row is `[opcode, first, second]`:

- `1 <= n <= 64`, `0 <= q <= 32`, and every initial frequency is in
  `0..1,000,000`.
- Opcode `0` adds `second` to the frequency at zero-based index `first`.
  `first` must be in `0..n`, `second` in `-1,000,000..1,000,000`, and the
  resulting frequency must remain in `0..1,000,000`.
- Opcode `1` asks for the one-based `first`-th occurrence and requires
  `second == 0`. The result is its zero-based frequency index. If `first <= 0`
  or `first` exceeds the current total frequency, that query returns `-1`.
- Unknown opcodes, invalid update rows, invalid initial frequencies, and
  malformed lengths make the whole call return `-1`.
- The exact input length is `2 + n + 3*q`; maximum valid and parseable lengths
  are 162 and 163 signed 64-bit words. Total frequency is at most 64,000,000.
- The scalar result is `sum((query_number+1) * (answer+1))` in query order.
  Thus an out-of-total rank contributes zero. Valid results are in
  `0..33,792`.

Each occurrence is tied to its index, and indices are ordered increasingly.
Repeated occurrences at one index occupy consecutive ranks. Binary lifting
advances over a Fenwick block only when its cumulative count is still below
the requested rank, so the returned index is the first one whose inclusive
prefix frequency reaches that rank.

## Distinction

The existing [`fenwick_tree`](../fenwick_tree/README.md) package supports
point additions and range sums, but not selection. The dynamic
[`ordered_set_avl_order_statistics`](../../o/ordered_set_avl_order_statistics/README.md)
uses subtree-size descent over unique arbitrary keys. The
[`segment_tree_max_right`](../../s/segment_tree_max_right/README.md) profile
uses segment-tree traversal for a general sum boundary predicate. This
package instead measures the Fenwick-specific binary-lifting walk over a
fixed-index multiset; each update and selection takes `O(log n)` time.

## References and review

The method is identified in CP-Algorithms'
[binary search article, “Search with powers of 2”](https://cp-algorithms.com/num_methods/binary_search.html#search-with-powers-of-2),
which notes adapting the pointer-and-power walk to select a nonzero Fenwick
element. Fenwick prefix blocks and point updates are described in the
[Fenwick tree article](https://cp-algorithms.com/data_structures/fenwick.html).
The implementation uses those algorithm descriptions only; all code, bounds,
oracles, and fixtures are independently written. The source site is licensed
under CC BY-SA 4.0; see [`RIGHTS.md`](RIGHTS.md).

The primary oracle builds and searches a Fenwick array. The independent oracle
scans frequencies in index order. [`workload.json`](workload.json) records
manually derived fixture results, and
[`verify_workload.py`](verify_workload.py) statically reviews fixture values,
Markdown targets, package inventory, and the ten exported source files. The
ports have not been compiled or run.

| Language | Source |
|---|---|
| C | [`c/f/fenwick_kth.c`](../../../c/f/fenwick_kth.c) |
| C3 | [`c3/f/fenwick_kth.c3`](../../../c3/f/fenwick_kth.c3) |
| C++ | [`cpp/f/fenwick_kth.cpp`](../../../cpp/f/fenwick_kth.cpp) |
| Elisa | [`elisa/f/fenwick_kth.elisa`](../../../elisa/f/fenwick_kth.elisa) |
| Mojo | [`mojo/f/fenwick_kth.mojo`](../../../mojo/f/fenwick_kth.mojo) |
| Nim | [`nim/f/fenwick_kth.nim`](../../../nim/f/fenwick_kth.nim) |
| Odin | [`odin/f/fenwick_kth.odin`](../../../odin/f/fenwick_kth.odin) |
| Rust | [`rust/f/fenwick_kth.rs`](../../../rust/f/fenwick_kth.rs) |
| V | [`v/f/fenwick_kth.v`](../../../v/f/fenwick_kth.v) |
| Zig | [`zig/f/fenwick_kth.zig`](../../../zig/f/fenwick_kth.zig) |
