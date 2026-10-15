package prime_factors

import "core:c"

decimal_length :: proc "contextless" (value: i64) -> c.size_t {
    length := c.size_t(1)
    remaining := value
    for remaining >= 10 {
        remaining /= 10
        length += 1
    }
    return length
}

required_length :: proc "contextless" (value: i64) -> c.size_t {
    length := c.size_t(0)
    count := c.size_t(0)
    remaining := value
    for divisor := i64(2); divisor <= remaining / divisor; divisor += 1 {
        for remaining % divisor == 0 {
            length += decimal_length(divisor)
            if count > 0 do length += 1
            count += 1
            remaining /= divisor
        }
    }
    if remaining > 1 {
        length += decimal_length(remaining)
        if count > 0 do length += 1
    }
    return length
}

append_decimal :: proc "contextless" (value: i64, output: [^]u8,
    position_value: c.size_t) -> c.size_t {
    digits: [10]u8
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

// Encode prime factors in ascending order, retaining multiplicity.
@(export)
prime_factors :: proc "c" (value: i64, output: [^]u8, output_capacity: c.size_t) -> i64 {
    if value < 1 || value > 2147483647 do return -1
    required := required_length(value)
    if output == nil || output_capacity < required do return -2
    position := c.size_t(0)
    count := c.size_t(0)
    remaining := value
    for divisor := i64(2); divisor <= remaining / divisor; divisor += 1 {
        for remaining % divisor == 0 {
            if count > 0 {
                output[position] = u8(',')
                position += 1
            }
            position = append_decimal(divisor, output, position)
            count += 1
            remaining /= divisor
        }
    }
    if remaining > 1 {
        if count > 0 {
            output[position] = u8(',')
            position += 1
        }
        position = append_decimal(remaining, output, position)
    }
    return i64(position)
}
