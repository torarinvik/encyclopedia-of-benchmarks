# Double Linear Search (Recursive)

This package searches a bounded integer list from both ends inward. Input is `[count, key, values...]`; the list length must equal `count`, with `0 <= count <= 1,024`. The key and every value are signed 32-bit integers. The search checks the current left item first, then the current right item, and continues toward the center. It returns the matching zero-based index or `-1` if the valid list does not contain the key. When a value occurs at both ends of the same interval, the left index wins.

The pinned Python function accepts generic comparable values and exposes optional `left` and `right` arguments. This workload covers its default full-list call on signed 32-bit integers. The source uses `right = right or len(list_data) - 1`; when a recursive interval reaches `right == 0`, that expression can reset the right bound and repeat an already-checked position. Under the default call, that repeated check does not change the returned index, so the ports use the equivalent bounded interval traversal while preserving its left-then-right visit order. Malformed input returns `-2`, distinct from the source's valid not-found result `-1`.

| Language | Port |
|---|---|
| C | [`c/d/double_linear_search_recursion.c`](../../../c/d/double_linear_search_recursion.c) |
| C3 | [`c3/d/double_linear_search_recursion.c3`](../../../c3/d/double_linear_search_recursion.c3) |
| C++ | [`cpp/d/double_linear_search_recursion.cpp`](../../../cpp/d/double_linear_search_recursion.cpp) |
| Elisa | [`elisa/d/double_linear_search_recursion.elisa`](../../../elisa/d/double_linear_search_recursion.elisa) |
| Nim | [`nim/d/double_linear_search_recursion.nim`](../../../nim/d/double_linear_search_recursion.nim) |
| Odin | [`odin/d/double_linear_search_recursion.odin`](../../../odin/d/double_linear_search_recursion.odin) |
| Rust | [`rust/d/double_linear_search_recursion.rs`](../../../rust/d/double_linear_search_recursion.rs) |
| V | [`v/d/double_linear_search_recursion.v`](../../../v/d/double_linear_search_recursion.v) |
| Zig | [`zig/d/double_linear_search_recursion.zig`](../../../zig/d/double_linear_search_recursion.zig) |

Pinned source: [TheAlgorithms/Python `double_linear_search_recursion.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/searches/double_linear_search_recursion.py). Its public `search` returns the first index encountered by the left-then-right inward scan, or `-1` when absent. See [`workload.json`](workload.json) for empty-list behavior, duplicate tie handling, integer boundaries, and malformed inputs.
