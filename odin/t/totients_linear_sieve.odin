package totients_linear_sieve

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
totients_linear_sieve :: proc "c" (n: i64, output: [^]u8, output_capacity: c.size_t) -> i64 {
    if n < 1 || n > 80 do return -1
    phi: [81]i64
    composite: [81]i64
    primes: [80]i64
    for i := i64(0); i <= n; i += 1 { phi[i] = 0; composite[i] = 0 }
    prime_count := c.size_t(0)
    phi[1] = 1
    for i := i64(2); i <= n; i += 1 {
        if composite[i] == 0 {
            primes[prime_count] = i
            prime_count += 1
            phi[i] = i - 1
        }
        for j := c.size_t(0); j < prime_count; j += 1 {
            p := primes[j]
            if i * p > n do break
            composite[i * p] = 1
            if i % p == 0 { phi[i * p] = phi[i] * p; break }
            phi[i * p] = phi[i] * (p - 1)
        }
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
