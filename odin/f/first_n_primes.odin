package first_n_primes

import "core:c"

is_prime :: proc "contextless" (value: i64) -> bool {
    if value < 2 do return false
    for divisor := i64(2); divisor <= value / divisor; divisor += 1 {
        if value % divisor == 0 do return false
    }
    return true
}

decimal_length :: proc "contextless" (value: i64) -> c.size_t {
    length := c.size_t(1)
    remaining := value
    for remaining >= 10 {
        remaining /= 10
        length += 1
    }
    return length
}

required_length :: proc "contextless" (number_of_primes: i64) -> c.size_t {
    length := c.size_t(0)
    count := c.size_t(0)
    value := i64(2)
    for count < c.size_t(number_of_primes) {
        if is_prime(value) {
            length += decimal_length(value)
            if count > 0 do length += 1
            count += 1
        }
        value += 1
    }
    return length
}

append_decimal :: proc "contextless" (value: i64, output: [^]u8,
    position_value: c.size_t) -> c.size_t {
    digits: [3]u8
    count := 0
    remaining := value
    for remaining > 0 {
        digits[count] = u8(remaining % 10)
        count += 1
        remaining /= 10
    }
    position := position_value
    for count > 0 {
        count -= 1
        output[position] = u8('0') + digits[count]
        position += 1
    }
    return position
}

// Encode the first n primes in ascending order as comma-separated decimal bytes.
@(export)
first_n_primes :: proc "c" (number_of_primes: i64, output: [^]u8,
    output_capacity: c.size_t) -> i64 {
    if number_of_primes < 0 || number_of_primes > 20 do return -1
    required := required_length(number_of_primes)
    if output == nil || output_capacity < required do return -2
    position := c.size_t(0)
    count := c.size_t(0)
    value := i64(2)
    for count < c.size_t(number_of_primes) {
        if is_prime(value) {
            if count > 0 {
                output[position] = u8(',')
                position += 1
            }
            position = append_decimal(value, output, position)
            count += 1
        }
        value += 1
    }
    return i64(position)
}
