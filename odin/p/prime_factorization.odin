package prime_factorization

import "core:c"

factor_pairs :: proc "contextless" (value: i64, primes, exponents: ^[10]u32) -> c.size_t {
    count := c.size_t(0)
    remaining := value
    for divisor := i64(2); divisor <= remaining / divisor; divisor += 1 {
        if remaining % divisor == 0 {
            exponent := u32(0)
            for remaining % divisor == 0 {
                remaining /= divisor
                exponent += 1
            }
            primes[count] = u32(divisor)
            exponents[count] = exponent
            count += 1
        }
    }
    if remaining > 1 {
        primes[count] = u32(remaining)
        exponents[count] = 1
        count += 1
    }
    return count
}

write_u32le :: proc "contextless" (value: u32, output: [^]u8, position: c.size_t) {
    for byte := c.size_t(0); byte < 4; byte += 1 {
        output[position + byte] = u8((value >> (8 * byte)) & 255)
    }
}

// Encode ascending prime/exponent pairs as little-endian u32 values.
@(export)
prime_factorization :: proc "c" (value: i64, output: [^]u8, output_capacity: c.size_t) -> i64 {
    if value < 1 || value > 1000005 do return -1
    primes: [10]u32
    exponents: [10]u32
    count := factor_pairs(value, &primes, &exponents)
    required := count * 8
    if output == nil || output_capacity < required do return -2
    for index := c.size_t(0); index < count; index += 1 {
        write_u32le(primes[index], output, 8 * index)
        write_u32le(exponents[index], output, 8 * index + 4)
    }
    return i64(required)
}
