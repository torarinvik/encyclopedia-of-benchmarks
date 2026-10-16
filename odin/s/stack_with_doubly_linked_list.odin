package stack_with_doubly_linked_list

import "core:c"

MAX_OPERATIONS :: 64
MAX_INPUT_LENGTH :: 129
MAX_OUTPUT_BYTES :: 1536

write_i64_le :: proc "contextless" (output: [^]u8, offset: usize, value: i64) {
    bits := u64(value)
    for byte: usize = 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits & 255)
        bits >>= 8
    }
}

write_record :: proc "contextless" (output: [^]u8, offset: usize, opcode, tag, value: i64) {
    write_i64_le(output, offset, opcode)
    write_i64_le(output, offset + 8, tag)
    write_i64_le(output, offset + 16, value)
}

@(export, link_name="stack_with_doubly_linked_list")
stack_with_doubly_linked_list :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > MAX_INPUT_LENGTH do return -1
    count_value := input[0]
    if count_value < 0 || count_value > MAX_OPERATIONS do return -1
    count := int(count_value)
    opcodes: [MAX_OPERATIONS]i64
    arguments: [MAX_OPERATIONS]i64
    cursor := 1
    for i := 0; i < count; i += 1 {
        if cursor >= int(length) do return -1
        opcode := input[cursor]
        cursor += 1
        opcodes[i] = opcode
        if opcode == 1 {
            if cursor >= int(length) do return -1
            value := input[cursor]
            cursor += 1
            if value < -2147483648 || value > 2147483647 do return -1
            arguments[i] = value
        } else if opcode < 2 || opcode > 4 {
            return -1
        }
    }
    if cursor != int(length) do return -1

    node_values: [MAX_OPERATIONS + 1]i64
    next_ids: [MAX_OPERATIONS + 1]usize
    prev_ids: [MAX_OPERATIONS + 1]usize
    buffer: [MAX_OUTPUT_BYTES]u8
    node_count, head, written := 0, 0, 0
    for i := 0; i < count; i += 1 {
        opcode := opcodes[i]
        tag, value := i64(2), i64(0)
        if opcode == 1 {
            node_count += 1
            node_values[node_count] = arguments[i]
            next_ids[node_count] = head
            prev_ids[node_count] = 0
            if head != 0 do prev_ids[head] = node_count
            head = node_count
        } else if opcode == 2 {
            if head != 0 {
                tag = 0
                value = node_values[head]
                head = next_ids[head]
                if head != 0 do prev_ids[head] = 0
            }
        } else if opcode == 3 {
            if head != 0 { tag = 0; value = node_values[head] }
        } else {
            tag = 0
            for node := head; node != 0; node = next_ids[node] { value += 1 }
        }
        write_record(buffer[:], written, opcode, tag, value)
        written += 24
    }
    if output == nil || capacity < c.size_t(written) do return -2
    for i := 0; i < written; i += 1 { output[i] = buffer[i] }
    return i64(written)
}
