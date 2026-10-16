package unique_letters_count

import "core:c"

MAX_TEXT_LENGTH :: 256
MAX_INPUT_LENGTH :: MAX_TEXT_LENGTH + 1
LETTER_COUNT :: 26
BYTES_PER_RECORD :: 8

store_i32_le :: proc "contextless" (output: [^]u8, position: int, value: i64) {
    bits := u32(i32(value))
    for byte := 0; byte < 4; byte += 1 {
        output[position + byte] = u8((bits >> u64(byte * 8)) & 255)
    }
}

@(export)
unique_letters_count :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
    text_length_value := input[0]
    if text_length_value < 0 || text_length_value > MAX_TEXT_LENGTH do return -1
    text_length := int(text_length_value)
    if text_length + 1 != int(length) do return -1

    for index := 0; index < text_length; index += 1 {
        value := input[index + 1]
        if value < 0 || value > 127 do return -1
    }

    frequencies: [26]i64 = {}
    first_seen: [26]i64 = {}
    unique_count := 0
    for index := 0; index < text_length; index += 1 {
        value := input[index + 1]
        if value >= 65 && value <= 90 {
            value += 32
        } else if value < 97 || value > 122 {
            continue
        }
        letter_index := int(value - 97)
        if frequencies[letter_index] == 0 {
            first_seen[unique_count] = value
            unique_count += 1
        }
        frequencies[letter_index] += 1
    }

    maximum_result := min(text_length, LETTER_COUNT)
    required_capacity := c.size_t(maximum_result * BYTES_PER_RECORD)
    if output_capacity < required_capacity || (required_capacity > 0 && output == nil) do return -2

    for index := 0; index < unique_count; index += 1 {
        letter := first_seen[index]
        store_i32_le(output, index * BYTES_PER_RECORD, letter)
        store_i32_le(output, index * BYTES_PER_RECORD + 4, frequencies[int(letter - 97)])
    }
    return i64(unique_count)
}
