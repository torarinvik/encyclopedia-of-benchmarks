package compute_totient

import "core:c"

decimal_length :: proc "contextless" (value: i64) -> c.size_t {
    length := c.size_t(1)
    for value >= 10 {
        value /= 10
        length += 1
    }
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
compute_totient :: proc "c" (n: i64, output: [^]u8, output_capacity: c.size_t) -> i64 {
    if n < 1 || n > 80 do return -1
    phi: [80]i64
    for i := i64(1); i <= n; i += 1 { phi[i - 1] = i }
    for p := i64(2); p <= n; p += 1 {
        if phi[p - 1] != p do continue
        phi[p - 1] = p - 1
        for i := 2 * p; i <= n; i += p {
            phi[i - 1] = (phi[i - 1] / p) * (p - 1)
        }
    }
    required := c.size_t(n - 1)
    for i := i64(0); i < n; i += 1 { required += decimal_length(phi[i]) }
    if output == nil || output_capacity < required do return -2
    position := c.size_t(0)
    for i := i64(0); i < n; i += 1 {
        if i > 0 { output[position] = u8(','); position += 1 }
        position = append_decimal(phi[i], output, position)
    }
    return i64(position)
}
