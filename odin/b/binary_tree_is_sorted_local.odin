package binary_tree_is_sorted_local

import "core:c"

MISSING_NODE :: i64(-2147483649)
MAX_SLOTS :: 255

@(export)
binary_tree_is_sorted_local :: proc "c" (nodes: [^]i64, length: c.size_t) -> i64 {
    if length == 0 || length > MAX_SLOTS || nodes == nil || nodes[0] == MISSING_NODE do return -1
    for index := c.size_t(0); index < length; index += 1 {
        value := nodes[index]
        if value == MISSING_NODE do continue
        if value < -2147483648 || value > 2147483647 do return -1
        if index > 0 {
            parent := (index - 1) / 2
            if nodes[parent] == MISSING_NODE do return -1
            if (index % 2 == 1 && value > nodes[parent]) ||
               (index % 2 == 0 && value < nodes[parent]) do return 0
        }
    }
    return 1
}
