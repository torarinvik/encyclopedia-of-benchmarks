package base_neg2_conversion

import "core:c"

// Convert a signed 64-bit integer to canonical negabinary digits.
@(export)
base_neg2_conversion :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if length != 1 do return -1
    width := c.size_t(0)
    remaining := input[0]
    for {
        quotient := remaining / 2
        digit := remaining % -2
        quotient = -quotient
        if digit < 0 { digit += 2; quotient += 1 }
        remaining = quotient
        width += 1
        if remaining == 0 do break
    }
    if output_capacity < width do return -2
    top := c.size_t(0)
    remaining = input[0]
    for {
        quotient := -(remaining / 2)
        digit := remaining % -2
        if digit < 0 { digit += 2; quotient += 1 }
        output[top] = u8('0') + u8(digit)
        top += 1
        remaining = quotient
        if remaining == 0 do break
    }
    left := c.size_t(0)
    right := top - 1
    for left < right {
        temporary := output[left]; output[left] = output[right]; output[right] = temporary
        left += 1; right -= 1
    }
    return i64(top)
}
