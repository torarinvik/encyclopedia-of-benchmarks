package narcissistic_number

import "core:c"

// Enumerate narcissistic numbers below limit, memoizing digit powers.
@(export)
narcissistic_number :: proc "c" (limit: i64, output: [^]u8, output_capacity: c.size_t) -> i64 {
    if limit > 100000 do return -1
    if limit <= 0 do return 0
    numbers: [32]i64
    powers: [60]i64
    cached: [60]bool
    for key := 0; key < 60; key += 1 { cached[key] = false }
    count := c.size_t(0)
    for number := i64(0); number < limit; number += 1 {
        digits := 1
        for remaining := number; remaining >= 10; remaining /= 10 { digits += 1 }
        sum := i64(0)
        for remaining := number; remaining > 0; remaining /= 10 {
            digit := int(remaining % 10)
            key := digits * 10 + digit
            if !cached[key] {
                power := i64(1)
                for exponent := 0; exponent < digits; exponent += 1 { power *= i64(digit) }
                powers[key] = power
                cached[key] = true
            }
            sum += powers[key]
        }
        if sum == number {
            if count == 32 do return -1
            numbers[count] = number
            count += 1
        }
    }
    required := count * 8
    if required == 0 do return 0
    if output == nil || output_capacity < required do return -2
    position := c.size_t(0)
    for item := c.size_t(0); item < count; item += 1 {
        value := u64(numbers[item])
        for byte := c.size_t(0); byte < 8; byte += 1 {
            shift := (7 - byte) * 8
            output[position] = u8(value >> shift)
            position += 1
        }
    }
    return i64(required)
}
