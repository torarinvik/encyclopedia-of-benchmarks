# Different views of a binary tree

The pinned Python implementation exposes four view functions. This benchmark selects one view for each call: `right` and `left` choose the last or first node at each depth in left-to-right breadth-first order; `top` chooses the first breadth-first node at each horizontal distance; `bottom` chooses the last. Top and bottom results are returned from the leftmost horizontal distance to the rightmost. The top-view values overlap `print_top_viewof_tree`, but that benchmark emits columns in discovery order; the left/right side views and bottom view are separate operations. Vertical order traversal returns every node rather than only the visible node per column.

## Contract

- Input is an indexed table of up to 1,023 `[value, left_index, right_index]` triplets. Values are signed 32-bit integers; `-1` means no child. The root may be any table index. Empty input uses root `-1`.
- `view` is one of `right`, `left`, `top`, or `bottom`.
- A nonempty input must describe one rooted tree with every node reachable exactly once.
- Return the selected values in view order. Empty input returns an empty sequence.
- Invalid inputs return `-1`; insufficient output capacity returns `-2`.

The C ABI receives the flattened node triplets, node count, root index, numeric view selector (`0` right, `1` left, `2` top, `3` bottom), output buffer, and its capacity. It returns the number of output values. The ports use a breadth-first traversal, which preserves the pinned source's left-before-right tie behavior.

## Ports

- [C](../../../c/d/diff_views_of_binary_tree.c)
- [C++](../../../cpp/d/diff_views_of_binary_tree.cpp)
- [C3](../../../c3/d/diff_views_of_binary_tree.c3)
- [Elisa](../../../elisa/d/diff_views_of_binary_tree.elisa)
- [Nim](../../../nim/d/diff_views_of_binary_tree.nim)
- [Odin](../../../odin/d/diff_views_of_binary_tree.odin)
- [Rust](../../../rust/d/diff_views_of_binary_tree.rs)
- [V](../../../v/d/diff_views_of_binary_tree.v)
- [Zig](../../../zig/d/diff_views_of_binary_tree.zig)
