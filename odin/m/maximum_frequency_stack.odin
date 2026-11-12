package maximum_frequency_stack

import "core:c"

store_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
maximum_frequency_stack :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > 130 do return -1
    count := input[0]
    if count < 0 || count > 64 || length != 1 + 2 * c.size_t(count) do return -1
    frequency: [17]int
    bucket_top: [65]int
    for i := 0; i < 65; i += 1 { bucket_top[i] = -1 }
    node_value: [64]int
    node_next: [64]int
    popped: [64]i64
    nodes, pop_count, position, maximum_frequency := 0, 0, 1, 0
    for operation := i64(0); operation < count; operation += 1 {
        opcode, argument := input[position], input[position + 1]
        position += 2
        if opcode == 0 {
            if argument < -8 || argument > 8 do return -1
            index := int(argument) + 8
            frequency[index] += 1
            level := frequency[index]
            node_value[nodes] = int(argument)
            node_next[nodes] = bucket_top[level]
            bucket_top[level] = nodes
            nodes += 1
            if level > maximum_frequency { maximum_frequency = level }
        } else if opcode == 1 && argument == 0 {
            if maximum_frequency == 0 || bucket_top[maximum_frequency] < 0 do return -1
            node := bucket_top[maximum_frequency]
            bucket_top[maximum_frequency] = node_next[node]
            value := node_value[node]
            popped[pop_count] = i64(value)
            pop_count += 1
            frequency[value + 8] -= 1
            if bucket_top[maximum_frequency] < 0 { maximum_frequency -= 1 }
        } else { return -1 }
    }
    needed := c.size_t(pop_count * 8)
    if needed > 0 && (output == nil || capacity < needed) do return -2
    for i := 0; i < pop_count; i += 1 { store_i64(output, i * 8, popped[i]) }
    return i64(needed)
}
