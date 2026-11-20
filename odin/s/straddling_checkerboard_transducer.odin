package straddling_checkerboard_transducer

import "core:c"

MAX_INPUT :: 97
MAX_TEXT :: 64
BOARD_SIZE :: 30
MAX_OUTPUT :: 128

parse_board :: proc(input: [^]i64, length: c.size_t, hole_a, hole_b: ^int,
                    text_length, mode: ^i64) -> bool {
    if input == nil || length < 32 || length > MAX_INPUT do return false
    mode^ = input[0]
    if mode^ != 0 && mode^ != 1 do return false
    holes := 0
    for position := 0; position < BOARD_SIZE; position += 1 {
        value := input[1 + position]
        if position < 10 && value == 0 {
            if holes == 0 { hole_a^ = position } else if holes == 1 { hole_b^ = position }
            holes += 1
            continue
        }
        if value < 32 || value > 126 do return false
        for prior := 0; prior < position; prior += 1 {
            if input[1 + prior] == value do return false
        }
    }
    if holes != 2 do return false
    text_length^ = input[31]
    if text_length^ < 0 || text_length^ > MAX_TEXT do return false
    return length == c.size_t(32 + text_length^)
}

find_symbol :: proc(input: [^]i64, value: i64) -> int {
    for position := 0; position < BOARD_SIZE; position += 1 {
        if input[1 + position] != 0 && input[1 + position] == value do return position
    }
    return -1
}

measure_decode :: proc(input: [^]i64, text_length: i64, hole_a, hole_b: int,
                       result_length: ^int) -> bool {
    result_length^ = 0
    index := i64(0)
    for index < text_length {
        value := input[32 + int(index)]
        if value < i64('0') || value > i64('9') do return false
        column := int(value - i64('0'))
        if input[1 + column] != 0 {
            result_length^ += 1
            index += 1
            continue
        }
        if (column != hole_a && column != hole_b) || index + 1 >= text_length do return false
        next := input[32 + int(index) + 1]
        if next < i64('0') || next > i64('9') do return false
        result_length^ += 1
        index += 2
    }
    return true
}

@(export)
straddling_checkerboard_transducer :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    hole_a, hole_b := -1, -1
    text_length, mode := i64(0), i64(-1)
    if !parse_board(input, length, &hole_a, &hole_b, &text_length, &mode) do return -1

    result_length := 0
    if mode == 0 {
        for index := i64(0); index < text_length; index += 1 {
            position := find_symbol(input, input[32 + int(index)])
            if position < 0 do return -1
            result_length += 1
            if position >= 10 { result_length += 1 }
        }
    } else if !measure_decode(input, text_length, hole_a, hole_b, &result_length) {
        return -1
    }
    if result_length > MAX_OUTPUT do return -1
    if output == nil || output_capacity < c.size_t(result_length) do return -2

    if mode == 0 {
        out := c.size_t(0)
        for index := i64(0); index < text_length; index += 1 {
            position := find_symbol(input, input[32 + int(index)])
            if position < 10 {
                output[out] = u8('0' + position)
                out += 1
            } else {
                row_digit := hole_a
                if position >= 20 { row_digit = hole_b }
                output[out] = u8('0' + row_digit)
                output[out + 1] = u8('0' + position % 10)
                out += 2
            }
        }
    } else {
        out := c.size_t(0)
        index := i64(0)
        for index < text_length {
            column := int(input[32 + int(index)] - i64('0'))
            if input[1 + column] != 0 {
                output[out] = u8(input[1 + column])
                index += 1
            } else {
                row := 1
                if column == hole_b { row = 2 }
                next_column := int(input[32 + int(index) + 1] - i64('0'))
                output[out] = u8(input[1 + row * 10 + next_column])
                index += 2
            }
            out += 1
        }
    }
    return i64(result_length)
}
