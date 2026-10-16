package xor_linked_list

import "core:c"

write_i64_le :: proc "contextless" (output: [^]u8, offset: usize, value: i64) {
    bits := u64(value)
    for byte: usize = 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export, link_name="xor_linked_list")
xor_linked_list :: proc "c" (input: [^]i64, length: c.size_t,
                              output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > 66 do return -1
    count_value := input[0]
    if count_value < 0 || count_value > 64 || length != c.size_t(count_value + 1) do return -1
    count := usize(count_value)
    for index: usize = 0; index < count; index += 1 {
        if input[index + 1] < -2147483648 || input[index + 1] > 2147483647 do return -1
    }
    needed := 8 + 8 * count
    if output == nil || capacity < c.size_t(needed) do return -2

    node_values: [65]i64
    both: [65]usize
    tail: usize = 0
    for index: usize = 0; index < count; index += 1 {
        node_id := index + 1
        node_values[node_id] = input[index + 1]
        both[node_id] = tail
        if tail != 0 do both[tail] = both[tail] ~ node_id
        tail = node_id
    }
    write_i64_le(output, 0, count_value)
    out: usize = 8
    previous: usize = 0
    current := if count == 0 { usize(0) } else { usize(1) }
    for current != 0 {
        write_i64_le(output, out, node_values[current])
        out += 8
        next_id := previous ~ both[current]
        previous = current
        current = next_id
    }
    return i64(needed)
}
