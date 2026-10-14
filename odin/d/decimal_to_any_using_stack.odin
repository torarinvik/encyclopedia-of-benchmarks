package decimal_to_any_using_stack

import "core:c"

// Convert a nonnegative signed 64-bit value with a LIFO digit stack.
@(export)
decimal_to_any_using_stack :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if length != 2 do return -1
    value, base := input[0], input[1]
    if value < 0 || base < 2 || base > 16 do return -1
    width := c.size_t(1)
    for remaining := value; remaining >= base; remaining /= base { width += 1 }
    if output_capacity < width do return -2
    top := c.size_t(0)
    remaining := value
    if remaining == 0 { output[top] = u8('0'); top += 1 }
    for remaining > 0 {
        digit := remaining % base
        if digit < 10 { output[top] = u8('0') + u8(digit) }
        else { output[top] = u8('A') + u8(digit - 10) }
        top += 1
        remaining /= base
    }
    left := c.size_t(0)
    right := top - 1
    for left < right {
        temporary := output[left]
        output[left] = output[right]
        output[right] = temporary
        left += 1
        right -= 1
    }
    return i64(top)
}
