package inv_of_formal_power_series

import "core:c"

MODULUS :: i64(998_244_353)
MAX_N :: 64
MAX_INPUT :: c.size_t(66)

power_mod :: proc(base_input, exponent_input: i64) -> i64 {
    base, exponent, result := base_input, exponent_input, i64(1)
    for exponent > 0 {
        if (exponent & 1) != 0 do result = result * base % MODULUS
        base = base * base % MODULUS
        exponent >>= 1
    }
    return result
}

store_le :: proc(output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
inv_of_formal_power_series :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT do return -1
    n_value := input[0]
    if n_value < 1 || n_value > i64(MAX_N) do return -1
    n := int(n_value)
    if int(length) != n + 1 do return -1
    for i := 0; i < n; i += 1 {
        if input[i+1] < 0 || input[i+1] >= MODULUS do return -1
    }
    if input[1] == 0 do return -1
    bytes := 8 * n
    if output == nil || int(capacity) < bytes do return -2

    inverse: [MAX_N]i64
    inverse_constant := power_mod(input[1], MODULUS-2)
    inverse[0] = inverse_constant
    for degree := 1; degree < n; degree += 1 {
        sum: i64 = 0
        for i := 1; i <= degree; i += 1 { sum = (sum + input[i+1]*inverse[degree-i]) % MODULUS }
        inverse[degree] = (MODULUS - inverse_constant*sum%MODULUS) % MODULUS
    }
    for i := 0; i < n; i += 1 { store_le(output, 8*i, inverse[i]) }
    return i64(bytes)
}
