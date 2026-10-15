package gronsfeld_cipher

import "core:c"

// Encrypt 7-bit ASCII with a repeating decimal-digit Gronsfeld key.
@(export)
gronsfeld_cipher :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if length < 1 || length > 321 do return -1
    separator := c.size_t(0)
    for separator < length && input[separator] != 0 { separator += 1 }
    if separator == length do return -1
    text_length := separator
    key_length := length - separator - 1
    if text_length > 256 || key_length > 64 do return -1

    for index := c.size_t(0); index < text_length; index += 1 {
        if input[index] < 1 || input[index] > 127 do return -1
    }
    for index := c.size_t(0); index < key_length; index += 1 {
        value := input[separator + 1 + index]
        if value < 48 || value > 57 do return -1
    }
    if key_length == 0 {
        for index := c.size_t(0); index < text_length; index += 1 {
            value := input[index]
            if (value >= 65 && value <= 90) || (value >= 97 && value <= 122) do return -1
        }
    }
    if output_capacity < text_length do return -2

    for index := c.size_t(0); index < text_length; index += 1 {
        value := input[index]
        mapped := value
        if value >= 65 && value <= 90 {
            shift := input[separator + 1 + index % key_length] - 48
            mapped = 65 + (value - 65 + shift) % 26
        } else if value >= 97 && value <= 122 {
            shift := input[separator + 1 + index % key_length] - 48
            mapped = 65 + (value - 97 + shift) % 26
        }
        output[index] = u8(mapped)
    }
    return i64(text_length)
}
