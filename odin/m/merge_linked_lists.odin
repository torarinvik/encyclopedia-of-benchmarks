package merge_linked_lists

import "core:c"

MAX_LIST_LENGTH :: 32
MAX_TOTAL_NODES :: 2 * MAX_LIST_LENGTH
MAX_PARSEABLE_INPUT_LENGTH :: 2 + MAX_TOTAL_NODES + 1

store_i64_le :: proc "c" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8((bits >> u64(8 * byte)) & 255)
    }
}

@(export)
merge_linked_lists :: proc "c" (values: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
    if values == nil || length < 2 || length > c.size_t(MAX_PARSEABLE_INPUT_LENGTH) do return -1
    raw_first := values[0]
    raw_second := values[1]
    if raw_first < 0 || raw_first > MAX_LIST_LENGTH || raw_second < 0 || raw_second > MAX_LIST_LENGTH do return -1
    first_length := int(raw_first)
    second_length := int(raw_second)
    total := first_length + second_length
    if total > MAX_TOTAL_NODES || int(length) != 2 + total do return -1

    node_values: [MAX_TOTAL_NODES]i32
    next: [MAX_TOTAL_NODES]int
    for index := 0; index < first_length; index += 1 {
        value := values[2 + index]
        if value < -2147483648 || value > 2147483647 do return -1
        node_values[index] = i32(value)
        next[index] = if index + 1 < first_length do index + 1 else -1
    }
    second_start := first_length
    for index := 0; index < second_length; index += 1 {
        value := values[2 + first_length + index]
        if value < -2147483648 || value > 2147483647 do return -1
        node := second_start + index
        node_values[node] = i32(value)
        next[node] = if index + 1 < second_length do node + 1 else -1
    }

    head1 := if first_length == 0 do -1 else 0
    head2 := if second_length == 0 do -1 else second_start
    temp1 := head1
    temp2 := head2
    holder2 := -1
    for temp1 != -1 && temp2 != -1 {
        holder1 := next[temp1]
        next[temp1] = temp2
        if holder1 != -1 {
            holder2 = next[temp2]
            next[temp2] = holder1
        }
        temp1 = holder1
        temp2 = holder2
    }

    output_count := 0
    node := head1
    for node != -1 {
        if node < 0 || node >= total || output_count >= total do return -1
        output_count += 1
        node = next[node]
    }
    required := output_count * 8
    if output == nil || capacity < c.size_t(required) do return -2

    node = head1
    for index := 0; index < output_count; index += 1 {
        store_i64_le(output, 8 * index, i64(node_values[node]))
        node = next[node]
    }
    return i64(required)
}
