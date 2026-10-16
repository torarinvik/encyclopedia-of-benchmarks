package union_of_two_arrays

import "core:c"

MAX_ARRAY_LENGTH :: 64
MAX_INPUT_LENGTH :: 2 * (MAX_ARRAY_LENGTH + 1)
BYTES_PER_VALUE :: 4

store_i32_le :: proc "contextless" (output: [^]u8, position: int, value: i64) {
    bits := u32(value)
    for byte := 0; byte < BYTES_PER_VALUE; byte += 1 {
        output[position + byte] = u8((bits >> u64(byte * 8)) & 255)
    }
}

@(export)
union_of_two_arrays :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
    first_length_value := input[0]
    if first_length_value < 0 || first_length_value > MAX_ARRAY_LENGTH do return -1
    first_length := int(first_length_value)
    second_length_position := 1 + first_length
    if second_length_position >= int(length) do return -1
    second_length_value := input[second_length_position]
    if second_length_value < 0 || second_length_value > MAX_ARRAY_LENGTH do return -1
    second_length := int(second_length_value)
    second_start := second_length_position + 1
    if second_start + second_length != int(length) do return -1

    for index := 0; index < first_length; index += 1 {
        value := input[1 + index]
        if value < -2147483648 || value > 2147483647 do return -1
        if index > 0 && input[index] > value do return -1
    }
    for index := 0; index < second_length; index += 1 {
        value := input[second_start + index]
        if value < -2147483648 || value > 2147483647 do return -1
        if index > 0 && input[second_start + index - 1] > value do return -1
    }

    maximum_result := first_length + second_length
    if output_capacity < c.size_t(maximum_result * BYTES_PER_VALUE) || (maximum_result > 0 && output == nil) do return -2
    first_index, second_index, result_count := 0, 0, 0
    previous_value: i64 = 0
    for first_index < first_length || second_index < second_length {
        value: i64
        if first_index == first_length {
            value = input[second_start + second_index]
            second_index += 1
        } else if second_index == second_length {
            value = input[1 + first_index]
            first_index += 1
        } else {
            first := input[1 + first_index]
            second := input[second_start + second_index]
            if first < second {
                value = first
                first_index += 1
            } else if first > second {
                value = second
                second_index += 1
            } else {
                value = first
                first_index += 1
                second_index += 1
            }
        }
        if result_count == 0 || value != previous_value {
            store_i32_le(output, result_count * BYTES_PER_VALUE, value)
            previous_value = value
            result_count += 1
        }
    }
    return i64(result_count)
}
