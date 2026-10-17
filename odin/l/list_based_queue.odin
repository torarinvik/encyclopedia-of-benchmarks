package list_based_queue

import "core:c"

@(export)
list_based_queue :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > 66 do return -1
    if input[0] < 0 || input[0] > 32 do return -1
    op_count := c.size_t(input[0])
    node_values: [32]i32
    next_node: [32]i32
    words: [64]i64
    allocated, word_count, pos, size: c.size_t = 0, 0, 1, 0
    head, tail: i32 = -1, -1
    for opi: c.size_t = 0; opi < op_count; opi += 1 {
        if pos >= length do return -1
        opcode := input[pos]
        pos += 1
        if opcode == 0 {
            if pos >= length do return -1
            value := input[pos]
            pos += 1
            if value < -2_147_483_648 || value > 2_147_483_647 || allocated >= 32 do return -1
            node := i32(allocated)
            allocated += 1
            node_values[node] = i32(value)
            next_node[node] = -1
            if tail < 0 do head = node
            else do next_node[tail] = node
            tail = node
            size += 1
            words[word_count] = 0; words[word_count+1] = 1; word_count += 2
        } else if opcode == 1 {
            if head < 0 do return -1
            node := head
            head = next_node[node]
            if head < 0 do tail = -1
            size -= 1
            words[word_count] = 1; words[word_count+1] = i64(node_values[node]); word_count += 2
        } else if opcode == 2 {
            if head < 0 do return -1
            words[word_count] = 2; words[word_count+1] = i64(node_values[head]); word_count += 2
        } else if opcode == 3 {
            head, tail = -1, -1; size = 0
            words[word_count] = 3; words[word_count+1] = 1; word_count += 2
        } else if opcode == 4 {
            words[word_count] = 4; words[word_count+1] = i64(size == 0); word_count += 2
        } else if opcode == 5 {
            words[word_count] = 5; words[word_count+1] = 0; word_count += 2
        } else do return -1
    }
    if pos != length || length > 1 + 2 * op_count || word_count > 64 do return -1
    bytes := word_count * 8
    if output == nil || output_capacity < bytes do return -2
    for i: c.size_t = 0; i < word_count; i += 1 {
        bits := u64(words[i])
        for b: c.size_t = 0; b < 8; b += 1 { output[8*i+b] = u8((bits >> (8*b)) & 255) }
    }
    return i64(bytes)
}
