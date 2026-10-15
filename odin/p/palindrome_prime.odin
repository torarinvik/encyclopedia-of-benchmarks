package palindrome_prime

import "core:c"

is_prime :: proc(value: u32) -> bool {
    if value < 2 do return false
    for divisor := u32(2); divisor <= value / divisor; divisor += 1 {
        if value % divisor == 0 do return false
    }
    return true
}

reverse_decimal :: proc(value: u32) -> u32 {
    remaining := value
    reversed := u32(0)
    for remaining > 0 {
        reversed = reversed * 10 + remaining % 10
        remaining /= 10
    }
    return reversed
}

write_u32_le :: proc(output: [^]u8, position: c.size_t, value: u32) {
    output[position] = u8(value)
    output[position + 1] = u8(value >> 8)
    output[position + 2] = u8(value >> 16)
    output[position + 3] = u8(value >> 24)
}

// Encode the first n palindrome primes as little-endian u32 values.
@(export)
palindrome_prime :: proc "c" (n: i64, output: [^]u8, output_capacity: c.size_t) -> i64 {
    if n > 16 do return -1
    if n <= 0 do return 0
    required := c.size_t(n) * 4
    if output == nil || output_capacity < required do return -2
    write_u32_le(output, 0, 2)
    count := c.size_t(1)
    for candidate := u32(3); count < c.size_t(n); candidate += 2 {
        if candidate == reverse_decimal(candidate) && is_prime(candidate) {
            write_u32_le(output, count * 4, candidate)
            count += 1
        }
    }
    return i64(required)
}
