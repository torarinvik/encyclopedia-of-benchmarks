package decimal_to_any_base

import "core:c"

// Convert a nonnegative signed 64-bit value to base 2 through 36.
@(export)
decimal_to_any_base :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if length != 2 do return -1
    value, base := input[0], input[1]
    if value < 0 || base < 2 || base > 36 do return -1
    width := c.size_t(1)
    for remaining := value; remaining >= base; remaining /= base { width += 1 }
    if output_capacity < width do return -2
    position := width
    remaining := value
    for position > 0 {
        position -= 1
        digit := remaining % base
        if digit < 10 {
            output[position] = u8('0') + u8(digit)
        } else {
            output[position] = u8('A') + u8(digit - 10)
        }
        remaining /= base
    }
    return i64(width)
}
