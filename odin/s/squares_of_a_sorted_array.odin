package squares_of_a_sorted_array

import "core:c"

MAX_ARRAY_LENGTH :: 10000

// Square a sorted array and emit the results in ascending order.
@(export)
squares_of_a_sorted_array :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if length > MAX_ARRAY_LENGTH || (length > 0 && input == nil) do return -1
    for index := 0; index < int(length); index += 1 {
        if input[index] < -10000 || input[index] > 10000 do return -1
        if index > 0 && input[index - 1] > input[index] do return -1
    }
    output_bytes := c.size_t(length * 8)
    if output_capacity < output_bytes || (output_bytes > 0 && output == nil) do return -2

    left, right, destination := 0, int(length), int(length)
    for destination > 0 {
        destination -= 1
        left_value, right_value := input[left], input[right - 1]
        left_magnitude := left_value
        if left_value < 0 { left_magnitude = -left_value }
        right_magnitude := right_value
        if right_value < 0 { right_magnitude = -right_value }
        value: i64
        if left_magnitude > right_magnitude {
            value = left_value
            left += 1
        } else {
            value = right_value
            right -= 1
        }
        square := u64(value * value)
        for byte := 0; byte < 8; byte += 1 {
            output[destination * 8 + byte] = u8((square >> u64(byte * 8)) & 255)
        }
    }
    return i64(length)
}
