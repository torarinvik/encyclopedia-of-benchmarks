package brainfuck

import "core:c"

// Interpret a bounded Brainfuck byte program with portable limits.
@(export)
brainfuck :: proc "c" (values: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    max_program :: 2048
    max_input :: 1024
    max_output :: 8192
    max_steps :: 100000
    tape_cells :: 257
    if values == nil || length < 2 || length > max_program + max_input + 2 do return -2
    if values[0] < 0 || values[0] > max_program do return -2
    program_length := c.size_t(values[0])
    input_length_index := program_length + 1
    if input_length_index >= length || values[input_length_index] < 0 || values[input_length_index] > max_input do return -2
    input_length := c.size_t(values[input_length_index])
    if length != program_length + input_length + 2 do return -2

    matching: [max_program]i32
    openings: [max_program]c.size_t
    for index: c.size_t = 0; index < program_length; index += 1 {
        matching[index] = -1
        byte := values[index + 1]
        if byte < 32 || byte > 126 do return -2
    }
    depth := c.size_t(0)
    for index: c.size_t = 0; index < program_length; index += 1 {
        byte := values[index + 1]
        if byte == '[' {
            openings[depth] = index
            depth += 1
        } else if byte == ']' {
            if depth == 0 do return -2
            depth -= 1
            opening := openings[depth]
            matching[opening] = i32(index)
            matching[index] = i32(opening)
        }
    }
    if depth != 0 do return -2
    for index: c.size_t = 0; index < input_length; index += 1 {
        byte := values[input_length_index + 1 + index]
        if byte < 0 || byte > 255 do return -2
    }

    tape: [tape_cells]u8
    scratch: [max_output]u8
    data_pointer := c.size_t(tape_cells / 2)
    input_index := c.size_t(0)
    instruction := c.size_t(0)
    steps := c.size_t(0)
    output_length := c.size_t(0)
    for instruction < program_length {
        steps += 1
        if steps > max_steps do return -2
        command := values[instruction + 1]
        if command == '.' {
            if output_length == max_output do return -2
            scratch[output_length] = tape[data_pointer]
            output_length += 1
        } else if command == ',' {
            if input_index < input_length {
                tape[data_pointer] = u8(values[input_length_index + 1 + input_index])
                input_index += 1
            } else {
                tape[data_pointer] = 0
            }
        } else if command == '>' {
            data_pointer += 1
            if data_pointer >= tape_cells do return -2
        } else if command == '<' {
            if data_pointer == 0 do return -2
            data_pointer -= 1
        } else if command == '+' {
            tape[data_pointer] += 1
        } else if command == '-' {
            tape[data_pointer] -= 1
        } else if command == '[' && tape[data_pointer] == 0 {
            instruction = c.size_t(matching[instruction])
        } else if command == ']' && tape[data_pointer] != 0 {
            instruction = c.size_t(matching[instruction])
        }
        instruction += 1
    }
    if output_length > output_capacity || (output_length != 0 && output == nil) do return -2
    for index: c.size_t = 0; index < output_length; index += 1 {
        output[index] = scratch[index]
    }
    return i64(output_length)
}
