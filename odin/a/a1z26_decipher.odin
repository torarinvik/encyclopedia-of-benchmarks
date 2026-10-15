package a1z26_decipher

import "core:c"

@(export)
a1z26_decipher :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if length > 66 do return -1
    for index := c.size_t(0); index < length; index += 1 {
        if input[index] < 1 || input[index] > 26 do return -1
    }
    if output_capacity < length do return -2
    for index := c.size_t(0); index < length; index += 1 {
        output[index] = u8(96 + input[index])
    }
    return i64(length)
}
