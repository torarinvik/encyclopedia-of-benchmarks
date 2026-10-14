package hexadecimal_to_binary

import "core:c"

// Convert a most-significant-first hexadecimal digit array to radix 2 text.
@(export)
hexadecimal_to_binary :: proc "c" (digits: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if length == 0 || length > 16 do return -1
    if length == 16 && digits[0] > 7 do return -1
    value: i64 = 0
    for index := c.size_t(0); index < length; index += 1 {
        hex_digit := digits[index]
        if hex_digit < 0 || hex_digit > 15 do return -1
        value = value * 16 + hex_digit
    }
    width := c.size_t(1)
    for remaining := value; remaining >= 2; remaining /= 2 { width += 1 }
    if output_capacity < width do return -2
    position := width
    remaining := value
    for position > 0 {
        position -= 1
        digit := remaining % 2
        if digit < 10 {
            output[position] = u8('0') + u8(digit)
        } else {
            output[position] = u8('a') + u8(digit - 10)
        }
        remaining /= 2
    }
    return i64(width)
}
