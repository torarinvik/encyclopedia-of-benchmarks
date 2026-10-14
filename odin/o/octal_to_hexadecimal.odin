package octal_to_hexadecimal

import "core:c"

// Convert a most-significant-first octal digit array to radix 16 text.
@(export)
octal_to_hexadecimal :: proc "c" (digits: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if length == 0 || length > 21 do return -1
    value: i64 = 0
    for index := c.size_t(0); index < length; index += 1 {
        octal_digit := digits[index]
        if octal_digit < 0 || octal_digit > 7 do return -1
        value = value * 8 + octal_digit
    }
    width := c.size_t(1)
    for remaining := value; remaining >= 16; remaining /= 16 { width += 1 }
    if output_capacity < width do return -2
    position := width
    remaining := value
    for position > 0 {
        position -= 1
        digit := remaining % 16
        if digit < 10 {
            output[position] = u8('0') + u8(digit)
        } else {
            output[position] = u8('a') + u8(digit - 10)
        }
        remaining /= 16
    }
    return i64(width)
}
