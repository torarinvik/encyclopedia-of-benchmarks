package sorted_list_to_bst

import "core:c"

emit_tree :: proc "contextless" (values: [^]i64, start, end: c.size_t,
        output: [^]u8, position: c.size_t) -> c.size_t {
    if start == end { output[position] = 0; return position + 1 }
    middle := start
    fast := start
    for fast < end && fast + 1 < end { fast += 2; middle += 1 }
    output[position] = 1
    encoded := values[middle]
    if encoded < 0 { encoded += 4294967296 }
    output[position + 1] = u8(encoded % 256)
    output[position + 2] = u8((encoded / 256) % 256)
    output[position + 3] = u8((encoded / 65536) % 256)
    output[position + 4] = u8(encoded / 16777216)
    next_position := emit_tree(values, start, middle, output, position + 5)
    return emit_tree(values, middle + 1, end, output, next_position)
}

// Build a height-balanced BST from a sorted linked-list value sequence and serialize it.
@(export)
sorted_list_to_bst :: proc "c" (values: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if length > 64 do return -1
    for index: c.size_t = 0; index < length; index += 1 {
        if values[index] < -2147483648 || values[index] > 2147483647 do return -1
        if index > 0 && values[index - 1] > values[index] do return -1
    }
    required := 6 * length + 1
    if output_capacity < required || output == nil do return -2
    emit_tree(values, 0, length, output, 0)
    return i64(length)
}
