package problem016_power_digit_sum

import "core:c"

@(export)
problem016_power_digit_sum :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length != 2 do return -1
    base := values[0]
    exponent := values[1]
    if base < 0 || base > 9 || exponent < 0 || exponent > 1000 do return -1

    digits: [1001]i64
    digits[0] = base
    digit_count := c.size_t(1)

    for power := i64(1); power < exponent; power += 1 {
        carry := i64(0)
        for index := c.size_t(0); index < digit_count; index += 1 {
            product := digits[index] * base + carry
            digits[index] = product % 10
            carry = product / 10
        }
        for carry > 0 {
            if digit_count >= 1001 do return -1
            digits[digit_count] = carry % 10
            digit_count += 1
            carry /= 10
        }
    }

    sum := i64(0)
    for index := c.size_t(0); index < digit_count; index += 1 {
        sum += digits[index]
    }
    return sum
}
