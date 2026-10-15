package factorial_large_number

import "core:c"

MAX_N :: 100
MAX_DIGITS :: 160

@(export)
factorial_large_number :: proc "c" (n: i64, output: [^]u8, output_capacity: c.size_t) -> i64 {
    if n < 0 || n > MAX_N do return -1
    digits: [MAX_DIGITS]i64
    digits[0] = 1
    digit_count := 1
    for factor: i64 = 2; factor <= n; factor += 1 {
        carry: i64 = 0
        for index := 0; index < digit_count; index += 1 {
            product := digits[index] * factor + carry
            digits[index] = product % 10
            carry = product / 10
        }
        for carry != 0 {
            digits[digit_count] = carry % 10
            digit_count += 1
            carry /= 10
        }
    }
    if output == nil || output_capacity < c.size_t(digit_count) do return -2
    for index := 0; index < digit_count; index += 1 {
        output[index] = u8('0' + digits[digit_count-index-1])
    }
    return i64(digit_count)
}
