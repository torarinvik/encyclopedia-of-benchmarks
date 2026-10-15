package xor_cipher

import "core:c"

@(export)
xor_cipher :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if length < 3 || length > 66 || input[0] < 0 || input[0] > 63 ||
        input[1] < 1 || input[1] > 63 { return -1 }
    text_length := c.size_t(input[0])
    key_length := c.size_t(input[1])
    if length != 2 + text_length + key_length do return -1
    for index := c.size_t(0); index < text_length + key_length; index += 1 {
        if input[2 + index] < 0 || input[2 + index] > 255 do return -1
    }
    if output_capacity < text_length do return -2
    for index := c.size_t(0); index < text_length; index += 1 {
        key_index := index % key_length
        output[index] = u8(input[2 + index] ~ input[2 + text_length + key_index])
    }
    return i64(text_length)
}
