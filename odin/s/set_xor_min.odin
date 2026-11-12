package set_xor_min

import "core:c"

MAX_Q :: 64
MAX_BITS :: 30
MAX_NODES :: 1 + MAX_BITS * MAX_Q
MAX_INPUT_VALUES :: 1 + 2 * MAX_Q
VALUE_LIMIT :: i64(1) << MAX_BITS

find_or_create_child :: proc(children: [^]int, node_count: ^int,
    node, direction: int) -> int {
    slot := node * 2 + direction
    child := children[slot]
    if child < 0 {
        child = node_count^
        node_count^ += 1
        children[child * 2] = -1
        children[child * 2 + 1] = -1
        children[slot] = child
    }
    return child
}

insert_value :: proc(children: [^]int, count: [^]int, node_count: ^int, value: u32) {
    path: [MAX_BITS + 1]int
    node := 0
    path[0] = 0
    for depth := 0; depth < MAX_BITS; depth += 1 {
        bit := MAX_BITS - 1 - depth
        direction := int((value >> u32(bit)) & 1)
        node = find_or_create_child(children, node_count, node, direction)
        path[depth + 1] = node
    }
    if count[node] != 0 do return
    for depth := 0; depth <= MAX_BITS; depth += 1 do count[path[depth]] += 1
}

remove_value :: proc(children: [^]int, count: [^]int, value: u32) {
    path: [MAX_BITS + 1]int
    node := 0
    path[0] = 0
    for depth := 0; depth < MAX_BITS; depth += 1 {
        bit := MAX_BITS - 1 - depth
        direction := int((value >> u32(bit)) & 1)
        node = children[node * 2 + direction]
        if node < 0 do return
        path[depth + 1] = node
    }
    if count[node] == 0 do return
    for depth := 0; depth <= MAX_BITS; depth += 1 do count[path[depth]] -= 1
}

minimum_xor :: proc(children: [^]int, count: [^]int, value: u32) -> u32 {
    node := 0
    result := u32(0)
    for bit := MAX_BITS - 1; bit >= 0; bit -= 1 {
        preferred := int((value >> u32(bit)) & 1)
        child := children[node * 2 + preferred]
        if child >= 0 && count[child] > 0 {
            node = child
        } else {
            result |= u32(1) << u32(bit)
            node = children[node * 2 + (preferred ^ 1)]
        }
    }
    return result
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits >> u64(8 * byte))
    }
}

@(export)
set_xor_min :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 3 || length > MAX_INPUT_VALUES do return -1
    q_value := input[0]
    if q_value < 1 || q_value > MAX_Q do return -1
    q := int(q_value)
    if length != c.size_t(1 + 2 * q) do return -1
    for operation := 0; operation < q; operation += 1 {
        offset := 1 + 2 * operation
        if input[offset] < 0 || input[offset] > 2 || input[offset + 1] < 0 ||
           input[offset + 1] >= VALUE_LIMIT do return -1
    }

    children: [MAX_NODES * 2]int
    count: [MAX_NODES]int
    for slot := 0; slot < MAX_NODES * 2; slot += 1 do children[slot] = -1
    node_count := 1
    answers: [MAX_Q]i64
    answer_count := 0
    for operation := 0; operation < q; operation += 1 {
        offset := 1 + 2 * operation
        kind := input[offset]
        value := u32(input[offset + 1])
        if kind == 0 {
            insert_value(&children[0], &count[0], &node_count, value)
        } else if kind == 1 {
            remove_value(&children[0], &count[0], value)
        } else {
            if count[0] == 0 do return -1
            answers[answer_count] = i64(minimum_xor(&children[0], &count[0], value))
            answer_count += 1
        }
    }

    required := 8 * answer_count
    if output == nil || capacity < c.size_t(required) do return -2
    for index := 0; index < answer_count; index += 1 {
        store_i64_le(output, 8 * index, answers[index])
    }
    return i64(required)
}
