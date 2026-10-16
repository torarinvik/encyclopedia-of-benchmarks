package ceil_in_binary_search_tree

import "core:c"

MAX_NODE_COUNT :: 127
MAX_INPUT_LENGTH :: 3 + 3 * MAX_NODE_COUNT
VALUE_MIN :: -1_000_000
VALUE_MAX :: 1_000_000
INVALID_RESULT :: i64(-9223372036854775807)
NO_CEIL_RESULT :: i64(-9223372036854775807 - 1)

@(export)
ceil_in_binary_search_tree :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 3 || length > MAX_INPUT_LENGTH do return INVALID_RESULT
    node_count_value := input[0]
    root_index_value := input[1]
    key := input[2]
    if node_count_value < 0 || node_count_value > MAX_NODE_COUNT || key < VALUE_MIN || key > VALUE_MAX do return INVALID_RESULT
    node_count := int(node_count_value)
    if int(length) != 3 + 3 * node_count do return INVALID_RESULT
    if node_count == 0 {
        if root_index_value == -1 do return NO_CEIL_RESULT
        return INVALID_RESULT
    }
    if root_index_value < 0 || root_index_value >= node_count_value do return INVALID_RESULT

    current := int(root_index_value)
    best := NO_CEIL_RESULT
    steps := 0
    for current >= 0 {
        if steps >= node_count do return INVALID_RESULT
        offset := 3 + 3 * current
        value := input[offset]
        left := input[offset+1]
        right := input[offset+2]
        if value < VALUE_MIN || value > VALUE_MAX || left < -1 || right < -1 || left >= node_count_value || right >= node_count_value do return INVALID_RESULT
        if value == key do return value
        if value < key do current = int(right)
        else { best = value; current = int(left) }
        steps += 1
    }
    return best
}
