package comparison

import "core:c"

MAX_STRING_LENGTH :: 64
MAX_INPUT_LENGTH :: 3 + 2 * MAX_STRING_LENGTH

fold_ascii :: proc "contextless" (value: i64, mode: i64) -> i64 {
    if mode == 1 && value >= 65 && value <= 90 do return value + 32
    return value
}

@(export)
comparison :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 3 || length > c.size_t(MAX_INPUT_LENGTH) do return -2
    mode := values[0]
    first_length_value := values[1]
    if (mode != 0 && mode != 1) || first_length_value < 0 || first_length_value > MAX_STRING_LENGTH do return -2
    first_length := int(first_length_value)
    second_length_position := 2 + first_length
    if second_length_position >= int(length) do return -2
    second_length_value := values[second_length_position]
    if second_length_value < 0 || second_length_value > MAX_STRING_LENGTH do return -2
    second_length := int(second_length_value)
    second_start := second_length_position + 1
    if second_start + second_length != int(length) do return -2

    for index := 0; index < first_length; index += 1 {
        value := values[2 + index]
        if value < 1 || value > 127 do return -2
    }
    for index := 0; index < second_length; index += 1 {
        value := values[second_start + index]
        if value < 1 || value > 127 do return -2
    }

    common_length := min(first_length, second_length)
    for index := 0; index < common_length; index += 1 {
        left := fold_ascii(values[2 + index], mode)
        right := fold_ascii(values[second_start + index], mode)
        if left < right do return -1
        if left > right do return 1
    }
    if first_length < second_length do return -1
    if first_length > second_length do return 1
    return 0
}
