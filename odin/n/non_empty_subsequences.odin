package non_empty_subsequences

import "core:c"

MAX_RUNES :: 8
MAX_INPUT_LENGTH :: MAX_RUNES + 2
BYTES_PER_VALUE :: 4

is_unicode_scalar :: proc "contextless" (value: i64) -> bool {
    return value >= 0 && value <= 0x10ffff && !(value >= 0xd800 && value <= 0xdfff)
}

store_u32_le :: proc "contextless" (output: [^]u8, position: int, value: u32) {
    for byte := 0; byte < BYTES_PER_VALUE; byte += 1 {
        output[position + byte] = u8((value >> u32(byte * 8)) & 255)
    }
}

emit_row :: proc "contextless" (current: [^]i32, length: int, output: [^]u8,
        output_cursor, row_count: ^int) {
    store_u32_le(output, output_cursor^, u32(length))
    output_cursor^ += BYTES_PER_VALUE
    for item := 0; item < length; item += 1 {
        store_u32_le(output, output_cursor^, u32(current[item]))
        output_cursor^ += BYTES_PER_VALUE
    }
    row_count^ += 1
}

generate :: proc "contextless" (values: [^]i32, n, start: int, current: [^]i32,
        current_length: int, output: [^]u8, output_cursor, row_count: ^int) {
    for index := start; index < n; index += 1 {
        current[current_length] = values[index]
        emit_row(current, current_length + 1, output, output_cursor, row_count)
        generate(values, n, index + 1, current, current_length + 1, output, output_cursor, row_count)
    }
}

@(export)
non_empty_subsequences :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > MAX_INPUT_LENGTH do return -1
    count_value := input[0]
    if count_value < 1 || count_value > MAX_RUNES || length != c.size_t(count_value + 1) do return -1
    n := int(count_value)
    values: [MAX_RUNES]i32
    for index := 0; index < n; index += 1 {
        value := input[index + 1]
        if !is_unicode_scalar(value) do return -1
        values[index] = i32(value)
    }

    rows := (1 << n) - 1
    value_count := n * (1 << (n - 1))
    required := c.size_t((rows + value_count) * BYTES_PER_VALUE)
    if output_capacity < required || output == nil do return -2

    current: [MAX_RUNES]i32
    output_cursor := 0
    emitted := 0
    generate(&values[0], n, 0, &current[0], 0, output, &output_cursor, &emitted)
    return i64(emitted)
}
