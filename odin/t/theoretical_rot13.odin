package theoretical_rot13

import "core:c"

@(export)
theoretical_rot13 :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if length > 66 do return -1
    for index := c.size_t(0); index < length; index += 1 {
        if input[index] < 1 || input[index] > 127 do return -1
    }
    if output_capacity < length do return -2
    for index := c.size_t(0); index < length; index += 1 {
        value := input[index]
        mapped := value
        if value >= i64('a') && value <= i64('z') {
            mapped = i64('a') + (value - i64('a') + 13) % 26
        }
        output[index] = u8(mapped)
    }
    return i64(length)
}
