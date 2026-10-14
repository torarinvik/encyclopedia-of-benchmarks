package any_base_to_any_base

import "core:c"

// Convert radix digits through checked decimal accumulation.
@(export)
any_base_to_any_base :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if length < 3 || length > 65 do return -1
    source_base, target_base := input[0], input[1]
    if source_base < 2 || source_base > 36 || target_base < 2 || target_base > 36 do return -1
    value: i64 = 0
    for index := c.size_t(2); index < length; index += 1 {
        digit := input[index]
        if digit < 0 || digit >= source_base do return -1
        if value > (9223372036854775807 - digit) / source_base do return -1
        value = value * source_base + digit
    }
    width := c.size_t(1)
    for remaining := value; remaining >= target_base; remaining /= target_base { width += 1 }
    if output_capacity < width do return -2
    top := c.size_t(0)
    remaining := value
    if remaining == 0 { output[top] = u8('0'); top += 1 }
    for remaining > 0 {
        digit := remaining % target_base
        if digit < 10 { output[top] = u8('0') + u8(digit) }
        else { output[top] = u8('A') + u8(digit - 10) }
        top += 1
        remaining /= target_base
    }
    left := c.size_t(0)
    right := top - 1
    for left < right {
        temporary := output[left]; output[left] = output[right]; output[right] = temporary
        left += 1; right -= 1
    }
    return i64(top)
}
