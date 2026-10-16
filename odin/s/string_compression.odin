package string_compression

import "core:c"

@(export)
string_compression :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if length > 64 || (length > 0 && input == nil) do return -1
    for index := c.size_t(0); index < length; index += 1 {
        if input[index] < 0 || input[index] > 127 do return -1
    }

    encoded_length := c.size_t(0)
    index := c.size_t(0)
    for index < length {
        end := index + 1
        for end < length && input[end] == input[index] { end += 1 }
        count := end - index
        encoded_length += 1
        if count > 1 {
            if count >= 10 { encoded_length += 2 } else { encoded_length += 1 }
        }
        index = end
    }
    if output_capacity < encoded_length || (encoded_length > 0 && output == nil) do return -2

    write_index := c.size_t(0)
    index = 0
    for index < length {
        end := index + 1
        for end < length && input[end] == input[index] { end += 1 }
        count := end - index
        output[write_index] = u8(input[index])
        write_index += 1
        if count > 1 {
            if count >= 10 {
                output[write_index] = u8(48 + count / 10)
                write_index += 1
            }
            output[write_index] = u8(48 + count % 10)
            write_index += 1
        }
        index = end
    }
    return i64(write_index)
}
