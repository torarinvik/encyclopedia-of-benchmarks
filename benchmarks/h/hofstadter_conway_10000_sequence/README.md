# Hofstadter-Conway $10,000 sequence

Return the one-based term `a(n)` of the Hofstadter-Conway sequence:

```text
a(1) = a(2) = 1
a(n) = a(a(n - 1)) + a(n - a(n - 1)), for n > 2
```

This is distinct from Hofstadter's Q sequence, which uses two previous terms
as offsets, and from the Figure–Figure pair, which has a different additive
recurrence and greedy complement rule.

## Bounded contract

The exported `hofstadter_conway_10000_sequence` function uses the
`i64_array_scalar` ABI. The exact input is one signed 64-bit word `[n]`, with
`2 <= n <= 8192`; index 1 is a recurrence seed but is not accepted as an input.
The maximum valid frame is one word and the maximum parseable frame is two
words, so an extra trailing word is rejected. Null, malformed, or out-of-range
input returns `-1`. The result is the signed 64-bit value `a(n)`.

The primary port fills a fixed table in increasing index order. Its recurrence
dependencies are `a(n - 1)`, then the indices `a(n - 1)` and
`n - a(n - 1)`. The independent reference follows those dependencies on demand
with an explicit stack and memo table. By induction, `1 <= a(k) <= k`: if
`p=a(n-1)`, then `1<=p<n`, both dependency indices are in `1..n-1`, and their
values sum to at most `p+(n-p)=n`. Thus all terms and intermediate sums fit
signed 64-bit, and the maximum fixed native table occupies exactly
`8193 * 8 = 65,544` bytes. Both implementations take `O(n)` time and `O(n)`
space.

Fixtures include the initial recurrence values and powers of two. MathWorld
records `a(2^k)/2^k = 1/2` for `k >= 1`, which supplies the pinned maximum-index
value `a(8192)=4096`. Source details and rights are in [RIGHTS.md](RIGHTS.md).

## References and workload

- [`primary_oracle.py`](primary_oracle.py) is the bottom-up table reference.
- [`independent_oracle.py`](independent_oracle.py) is the demand-driven
  dependency-stack and memo reference.
- [`workload.json`](workload.json) contains valid terms, framing errors, and
  domain-boundary cases.
- [`verify_workload.py`](verify_workload.py) statically reconciles fixtures
  with both references.
- [`check_inventory.py`](check_inventory.py) checks package metadata and all
  ten source paths without compiling or executing language ports.
- [`INVENTORY.md`](INVENTORY.md) lists source paths and the exported ABI.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/h/hofstadter_conway_10000_sequence.c`](../../../c/h/hofstadter_conway_10000_sequence.c) |
| C3 | [`c3/h/hofstadter_conway_10000_sequence.c3`](../../../c3/h/hofstadter_conway_10000_sequence.c3) |
| C++ | [`cpp/h/hofstadter_conway_10000_sequence.cpp`](../../../cpp/h/hofstadter_conway_10000_sequence.cpp) |
| Elisa | [`elisa/h/hofstadter_conway_10000_sequence.elisa`](../../../elisa/h/hofstadter_conway_10000_sequence.elisa) |
| Mojo | [`mojo/h/hofstadter_conway_10000_sequence.mojo`](../../../mojo/h/hofstadter_conway_10000_sequence.mojo) |
| Nim | [`nim/h/hofstadter_conway_10000_sequence.nim`](../../../nim/h/hofstadter_conway_10000_sequence.nim) |
| Odin | [`odin/h/hofstadter_conway_10000_sequence.odin`](../../../odin/h/hofstadter_conway_10000_sequence.odin) |
| Rust | [`rust/h/hofstadter_conway_10000_sequence.rs`](../../../rust/h/hofstadter_conway_10000_sequence.rs) |
| V | [`v/h/hofstadter_conway_10000_sequence.v`](../../../v/h/hofstadter_conway_10000_sequence.v) |
| Zig | [`zig/h/hofstadter_conway_10000_sequence.zig`](../../../zig/h/hofstadter_conway_10000_sequence.zig) |
