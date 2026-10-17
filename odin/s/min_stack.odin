package min_stack

import "core:c"

MAX_OPERATIONS :: 256
MAX_INPUT_VALUES :: 513
MAX_OUTPUT_BYTES :: 6152

write_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export, link_name="min_stack")
min_stack :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > MAX_INPUT_VALUES do return -1
    count_value := input[0]
    if count_value < 0 || count_value > MAX_OPERATIONS do return -1
    count := int(count_value)

    opcodes: [MAX_OPERATIONS]i64
    operands: [MAX_OPERATIONS]i64
    position := 1
    query_count := 0
    for index := 0; index < count; index += 1 {
        if position >= int(length) do return -1
        opcode := input[position]
        position += 1
        operand: i64 = 0
        if opcode == 0 {
            if position >= int(length) do return -1
            operand = input[position]
            position += 1
            if operand < -2_147_483_648 || operand > 2_147_483_647 do return -1
        } else if opcode == 2 || opcode == 3 {
            query_count += 1
        } else if opcode != 1 {
            return -1
        }
        opcodes[index] = opcode
        operands[index] = operand
    }
    if position != int(length) do return -1

    needed := (1 + 3 * query_count) * 8
    if output == nil || capacity < c.size_t(needed) do return -2

    buffer: [MAX_OUTPUT_BYTES]u8
    write_i64_le(buffer[:], 0, i64(query_count))
    stack_values: [MAX_OPERATIONS]i64
    stack_minima: [MAX_OPERATIONS]i64
    depth := 0
    record := 1
    for index := 0; index < count; index += 1 {
        opcode := opcodes[index]
        if opcode == 0 {
            value := operands[index]
            stack_values[depth] = value
            stack_minima[depth] = value
            if depth > 0 && stack_minima[depth - 1] < value {
                stack_minima[depth] = stack_minima[depth - 1]
            }
            depth += 1
        } else if opcode == 1 {
            if depth > 0 do depth -= 1
        } else {
            exception_flag: i64 = 0
            value: i64 = 0
            if depth == 0 {
                exception_flag = 1
            } else if opcode == 2 {
                value = stack_values[depth - 1]
            } else {
                value = stack_minima[depth - 1]
            }
            write_i64_le(buffer[:], record * 8, opcode)
            write_i64_le(buffer[:], (record + 1) * 8, exception_flag)
            write_i64_le(buffer[:], (record + 2) * 8, value)
            record += 3
        }
    }
    for index := 0; index < needed; index += 1 { output[index] = buffer[index] }
    return i64(needed)
}
