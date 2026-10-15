package digit_separation

import "core:c"

// Separate signed decimal digits; direction 0 is reverse and 1 is forward.
@(export)
digit_separation :: proc "c" (input: [^]i64, input_length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || input_length != 2 || (input[1] != 0 && input[1] != 1) do return -1
    remaining := input[0]
    digits: [20]u8
    count := c.size_t(0)
    if remaining == 0 {
        digits[0] = 0
        count = 1
    }
    for remaining != 0 {
        remainder := remaining % 10
        if remainder < 0 do remainder = -remainder
        digits[count] = u8(remainder)
        count += 1
        remaining /= 10
    }
    if output == nil || output_capacity < count do return -2
    for index := c.size_t(0); index < count; index += 1 {
        source := index
        if input[1] == 1 do source = count - index - 1
        output[index] = digits[source]
    }
    return i64(count)
}
