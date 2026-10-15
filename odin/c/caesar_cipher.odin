package caesar_cipher

import "core:c"

@(export)
caesar_cipher :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if length == 0 || length > 66 do return -1
    text_length := length - 1
    for index := c.size_t(0); index < text_length; index += 1 {
        if input[index] < 0 || input[index] > 127 do return -1
    }
    if output_capacity < text_length do return -2

    shift := input[text_length] % 26
    if shift < 0 do shift += 26
    for index := c.size_t(0); index < text_length; index += 1 {
        value := input[index]
        mapped := value
        if value >= 65 && value <= 90 {
            mapped = 65 + (value - 65 + shift) % 26
        } else if value >= 97 && value <= 122 {
            mapped = 97 + (value - 97 + shift) % 26
        }
        output[index] = u8(mapped)
    }
    return i64(text_length)
}
