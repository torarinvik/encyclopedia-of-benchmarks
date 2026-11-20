# Static package inventory

Algorithm: minimum unfairness by selecting exactly `K` values

ABI: `i64_array_scalar`, symbol `minimum_unfairness_k_selection`

Input: `[N, K, value_0, ..., value_(N-1)]`, `2 <= K <= N <= 64`, values in `[-1,000,000,000, 1,000,000,000]`.

Output: minimum selected range width, `0..=2,000,000,000`; invalid input returns `-1`.

| Language | Source |
| --- | --- |
| C | [`c/m/minimum_unfairness_k_selection.c`](../../../c/m/minimum_unfairness_k_selection.c) |
| C3 | [`c3/m/minimum_unfairness_k_selection.c3`](../../../c3/m/minimum_unfairness_k_selection.c3) |
| C++ | [`cpp/m/minimum_unfairness_k_selection.cpp`](../../../cpp/m/minimum_unfairness_k_selection.cpp) |
| Elisa | [`elisa/m/minimum_unfairness_k_selection.elisa`](../../../elisa/m/minimum_unfairness_k_selection.elisa) |
| Mojo | [`mojo/m/minimum_unfairness_k_selection.mojo`](../../../mojo/m/minimum_unfairness_k_selection.mojo) |
| Nim | [`nim/m/minimum_unfairness_k_selection.nim`](../../../nim/m/minimum_unfairness_k_selection.nim) |
| Odin | [`odin/m/minimum_unfairness_k_selection.odin`](../../../odin/m/minimum_unfairness_k_selection.odin) |
| Rust | [`rust/m/minimum_unfairness_k_selection.rs`](../../../rust/m/minimum_unfairness_k_selection.rs) |
| V | [`v/m/minimum_unfairness_k_selection.v`](../../../v/m/minimum_unfairness_k_selection.v) |
| Zig | [`zig/m/minimum_unfairness_k_selection.zig`](../../../zig/m/minimum_unfairness_k_selection.zig) |

Package support files: [`workload.json`](workload.json), [`primary_oracle.py`](primary_oracle.py), [`independent_oracle.py`](independent_oracle.py), [`RIGHTS.md`](RIGHTS.md), [`inventory.json`](inventory.json), and [`check_inventory.py`](check_inventory.py).

Static source inventory describes expected files and exported symbol names. No executable validation was run.
