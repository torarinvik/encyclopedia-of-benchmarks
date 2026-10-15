package bifid_cipher

import "core:c"

letter_index :: proc(value: i64, merge_j: bool) -> i64 {
    normalized := value
    if normalized >= 97 && normalized <= 122 do normalized -= 32
    if normalized < 65 || normalized > 90 do return -1
    index := normalized - 65
    if index == 9 {
        if !merge_j do return -1
        index = 8
    } else if index > 9 {
        index -= 1
    }
    return index
}

letter_for_index :: proc(index: c.size_t) -> u8 {
    value := 97 + index
    if index >= 9 do value += 1
    return u8(value)
}

// Fractionate a fixed-square Bifid cipher over one complete message block.
@(export)
bifid_cipher :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 258 do return -1
    mode := input[0]
    text_length_value := input[1]
    if (mode != 0 && mode != 1) || text_length_value < 0 || text_length_value > 256 do return -1
    text_length := c.size_t(text_length_value)
    if length != text_length + 2 do return -1

    rows: [256]u8
    columns: [256]u8
    coordinates: [512]u8
    result: [256]u8
    result_length := c.size_t(0)

    if mode == 0 {
        for i := c.size_t(0); i < text_length; i += 1 {
            value := input[i + 2]
            if value == 32 do continue
            index := letter_index(value, true)
            if index < 0 do return -1
            rows[result_length] = u8(index / 5 + 1)
            columns[result_length] = u8(index % 5 + 1)
            result_length += 1
        }
        for i := c.size_t(0); i < result_length; i += 1 {
            coordinates[i] = rows[i]
            coordinates[result_length + i] = columns[i]
        }
        for i := c.size_t(0); i < result_length; i += 1 {
            row := c.size_t(coordinates[2 * i] - 1)
            column := c.size_t(coordinates[2 * i + 1] - 1)
            result[i] = letter_for_index(row * 5 + column)
        }
    } else {
        result_length = text_length
        for i := c.size_t(0); i < text_length; i += 1 {
            index := letter_index(input[i + 2], false)
            if index < 0 do return -1
            coordinates[2 * i] = u8(index / 5 + 1)
            coordinates[2 * i + 1] = u8(index % 5 + 1)
        }
        for i := c.size_t(0); i < result_length; i += 1 {
            row := c.size_t(coordinates[i] - 1)
            column := c.size_t(coordinates[result_length + i] - 1)
            result[i] = letter_for_index(row * 5 + column)
        }
    }

    if output_capacity < result_length || (result_length > 0 && output == nil) do return -2
    for i := c.size_t(0); i < result_length; i += 1 do output[i] = result[i]
    return i64(result_length)
}
