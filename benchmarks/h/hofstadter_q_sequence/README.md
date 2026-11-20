# Hofstadter Q sequence

Return the one-based term `Q(n)` of Hofstadter's Q sequence. This is a nested,
nonlinear recurrence and is distinct from the local Figure–Figure pair, whose
terms use an additive recurrence plus greedy complementary selection.

## Bounded contract

The exported `hofstadter_q_sequence` function uses the `i64_array_scalar` ABI.
Input is exactly one signed 64-bit word `[n]`, with `1 <= n <= 128`; the
maximum valid frame is one word and the maximum parseable frame is two words
(so an extra trailing word is rejected). The result is `Q(n)`. Null, malformed,
or out-of-domain input returns `-1`. The fixed table workspace is 2,048 bytes.

The supported prefix is deliberately finite. OEIS A005185 reports the
recurrence through index 128, while global definedness of the recurrence is
not known. This package makes no claim beyond the checked prefix. During
generation, an index outside the already constructed positive prefix is
rejected as undefined rather than read.

The primary algorithm fills a table from `Q(1)=Q(2)=1`, using
`Q(i)=Q(i-Q(i-1))+Q(i-Q(i-2))` for `i>2`. It takes `O(n)` time and `O(n)`
space. The independent reference evaluates the same defining recurrence with
memoized recursion and explicit cycle/index guards, rather than filling the
prefix in increasing order.

The first terms begin `1, 1, 2, 3, 3, 4, 5, 5, 6, 6, ...`; pinned fixtures
also cover the known values `Q(32)=17`, `Q(64)=33`, `Q(96)=64`, and
`Q(128)=64`. The title in the [RosettaGit task index](https://rosettagit.org/tasks/)
was used only for discovery. Method provenance and rights are in
[RIGHTS.md](RIGHTS.md).

## Package references and workload

- [`primary_oracle.py`](primary_oracle.py) is the bottom-up table reference.
- [`independent_oracle.py`](independent_oracle.py) is a memoized recursive
  reference with separate dependency evaluation.
- [`workload.json`](workload.json) contains deterministic terms and malformed
  framing/domain cases.
- [`check_inventory.py`](check_inventory.py) checks files and fixture/reference
  consistency statically. It does not compile or run language ports.
- [`INVENTORY.md`](INVENTORY.md) lists all ten source ports.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/h/hofstadter_q_sequence.c`](../../../c/h/hofstadter_q_sequence.c) |
| C3 | [`c3/h/hofstadter_q_sequence.c3`](../../../c3/h/hofstadter_q_sequence.c3) |
| C++ | [`cpp/h/hofstadter_q_sequence.cpp`](../../../cpp/h/hofstadter_q_sequence.cpp) |
| Elisa | [`elisa/h/hofstadter_q_sequence.elisa`](../../../elisa/h/hofstadter_q_sequence.elisa) |
| Mojo | [`mojo/h/hofstadter_q_sequence.mojo`](../../../mojo/h/hofstadter_q_sequence.mojo) |
| Nim | [`nim/h/hofstadter_q_sequence.nim`](../../../nim/h/hofstadter_q_sequence.nim) |
| Odin | [`odin/h/hofstadter_q_sequence.odin`](../../../odin/h/hofstadter_q_sequence.odin) |
| Rust | [`rust/h/hofstadter_q_sequence.rs`](../../../rust/h/hofstadter_q_sequence.rs) |
| V | [`v/h/hofstadter_q_sequence.v`](../../../v/h/hofstadter_q_sequence.v) |
| Zig | [`zig/h/hofstadter_q_sequence.zig`](../../../zig/h/hofstadter_q_sequence.zig) |
