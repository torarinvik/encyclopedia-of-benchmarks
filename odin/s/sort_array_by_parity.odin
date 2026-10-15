package sort_array_by_parity

import "core:c"

MAX_ARRAY_LENGTH :: 5000

// Place evens first and fill the odd section from its end.
@(export)
sort_array_by_parity :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if length > MAX_ARRAY_LENGTH || (length > 0 && input == nil) do return -1
    for index := 0; index < int(length); index += 1 {
        if input[index] < 0 || input[index] > 5000 do return -1
    }
    output_bytes := c.size_t(length * 4)
    if output_capacity < output_bytes || (output_bytes > 0 && output == nil) do return -2

    even_index, odd_index := 0, int(length)
    for index := 0; index < int(length); index += 1 {
        value := u32(input[index])
        destination: int
        if (value & 1) == 0 {
            destination = even_index
            even_index += 1
        } else {
            odd_index -= 1
            destination = odd_index
        }
        for byte := 0; byte < 4; byte += 1 {
            output[destination * 4 + byte] = u8((value >> u32(byte * 8)) & 255)
        }
    }
    return i64(length)
}
