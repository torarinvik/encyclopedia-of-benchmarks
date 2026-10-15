package atbash_cipher

import "core:c"

@(export)
atbash_cipher :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if length > 66 do return -1
    for index := c.size_t(0); index < length; index += 1 {
        if input[index] < 0 || input[index] > 127 do return -1
    }
    if output_capacity < length do return -2
    for index := c.size_t(0); index < length; index += 1 {
        value := input[index]
        mapped := value
        if value >= 65 && value <= 90 {
            mapped = 155 - value
        } else if value >= 97 && value <= 122 {
            mapped = 219 - value
        }
        output[index] = u8(mapped)
    }
    return i64(length)
}
