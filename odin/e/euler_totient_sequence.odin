package euler_totient_sequence

import "core:c"

decimal_length :: proc "contextless" (value: i64) -> c.size_t {
    length := c.size_t(1)
    remaining := value
    for remaining >= 10 { remaining /= 10; length += 1 }
    return length
}

append_decimal :: proc "contextless" (value_input: i64, output: [^]u8, position_input: c.size_t) -> c.size_t {
    digits: [3]u8
    count := c.size_t(0)
    value := value_input
    for {
        digits[count] = u8(value % 10)
        count += 1
        value /= 10
        if value == 0 do break
    }
    position := position_input
    for count > 0 {
        count -= 1
        output[position] = u8('0') + digits[count]
        position += 1
    }
    return position
}

@(export)
euler_totient_sequence :: proc "c" (n: i64, output: [^]u8, output_capacity: c.size_t) -> i64 {
    if n < 1 || n > 80 do return -1
    phi: [81]i64
    for value := i64(1); value <= n; value += 1 {
        remaining := value
        totient := value
        for p := i64(2); p * p <= remaining; p += 1 {
            if remaining % p != 0 do continue
            for remaining % p == 0 { remaining /= p }
            totient -= totient / p
        }
        if remaining > 1 { totient -= totient / remaining }
        phi[value] = totient
    }
    required := c.size_t(n - 1)
    for i := i64(1); i <= n; i += 1 { required += decimal_length(phi[i]) }
    if output == nil || output_capacity < required do return -2
    position := c.size_t(0)
    for i := i64(1); i <= n; i += 1 {
        if i > 1 { output[position] = u8(','); position += 1 }
        position = append_decimal(phi[i], output, position)
    }
    return i64(position)
}
