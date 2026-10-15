package run_length_encoding

import "core:c"

@(export)
run_length_encoding :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if length > 66 do return -1
    for index := c.size_t(0); index < length; index += 1 {
        value := input[index]
        if value < 1 || value > 127 || (value >= 48 && value <= 57) do return -1
    }

    encoded_length := c.size_t(0)
    index := c.size_t(0)
    for index < length {
        end := index + 1
        for end < length && input[end] == input[index] { end += 1 }
        count := end - index
        if count >= 10 { encoded_length += 3 } else { encoded_length += 2 }
        index = end
    }
    if output_capacity < encoded_length do return -2

    write_index := c.size_t(0)
    index = 0
    for index < length {
        end := index + 1
        for end < length && input[end] == input[index] { end += 1 }
        count := end - index
        if count >= 10 {
            output[write_index] = u8(48 + count / 10)
            write_index += 1
        }
        output[write_index] = u8(48 + count % 10)
        write_index += 1
        output[write_index] = u8(input[index])
        write_index += 1
        index = end
    }
    return i64(write_index)
}
