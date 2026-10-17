package min_stack_using_two_stacks

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

@(export, link_name="min_stack_using_two_stacks")
min_stack_using_two_stacks :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > MAX_INPUT_VALUES do return -1
    count_value := input[0]
    if count_value < 0 || count_value > MAX_OPERATIONS do return -1
    count := int(count_value)

    opcodes: [MAX_OPERATIONS]i64
    operands: [MAX_OPERATIONS]i64
    position := 1
    event_count := 0
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
        } else if opcode == 1 || opcode == 2 || opcode == 3 {
            event_count += 1
        } else {
            return -1
        }
        opcodes[index] = opcode
        operands[index] = operand
    }
    if position != int(length) do return -1

    needed := (1 + 3 * event_count) * 8
    if output == nil || capacity < c.size_t(needed) do return -2

    buffer: [MAX_OUTPUT_BYTES]u8
    write_i64_le(buffer[:], 0, i64(event_count))
    stack: [MAX_OPERATIONS]i64
    minima: [MAX_OPERATIONS]i64
    depth := 0
    minimum_depth := 0
    record := 1
    for index := 0; index < count; index += 1 {
        opcode := opcodes[index]
        if opcode == 0 {
            value := operands[index]
            stack[depth] = value
            depth += 1
            if minimum_depth == 0 || value <= minima[minimum_depth - 1] {
                minima[minimum_depth] = value
                minimum_depth += 1
            }
        } else if opcode == 1 {
            exception_flag: i64 = 0
            if depth == 0 {
                exception_flag = 1
            } else {
                depth -= 1
                if stack[depth] == minima[minimum_depth - 1] do minimum_depth -= 1
            }
            write_i64_le(buffer[:], record * 8, 1)
            write_i64_le(buffer[:], (record + 1) * 8, exception_flag)
            write_i64_le(buffer[:], (record + 2) * 8, 0)
            record += 3
        } else {
            exception_flag: i64 = 0
            value: i64 = 0
            if depth == 0 {
                exception_flag = 1
            } else if opcode == 2 {
                value = stack[depth - 1]
            } else {
                value = minima[minimum_depth - 1]
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
