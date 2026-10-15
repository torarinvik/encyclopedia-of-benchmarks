package vigenere_cipher

import "core:c"

@(export)
vigenere_cipher :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if length < 2 || length > 66 do return -1
    separator := c.size_t(0)
    for separator < length && input[separator] != 0 { separator += 1 }
    if separator == length || separator + 1 == length do return -1
    key_length := length - separator - 1
    for index := c.size_t(0); index < separator; index += 1 {
        if input[index] < 1 || input[index] > 127 do return -1
    }
    for index := c.size_t(0); index < key_length; index += 1 {
        value := input[separator + 1 + index]
        if !((value >= 65 && value <= 90) || (value >= 97 && value <= 122)) do return -1
    }
    if output_capacity < separator do return -2

    key_index := c.size_t(0)
    for index := c.size_t(0); index < separator; index += 1 {
        value := input[index]
        mapped := value
        if value >= 65 && value <= 90 {
            key_value := input[separator + 1 + key_index]
            if key_value >= 97 do key_value -= 32
            mapped = 65 + (value - 65 + key_value - 65) % 26
            key_index = (key_index + 1) % key_length
        } else if value >= 97 && value <= 122 {
            key_value := input[separator + 1 + key_index]
            if key_value <= 90 do key_value += 32
            mapped = 97 + (value - 97 + key_value - 97) % 26
            key_index = (key_index + 1) % key_length
        }
        output[index] = u8(mapped)
    }
    return i64(separator)
}
