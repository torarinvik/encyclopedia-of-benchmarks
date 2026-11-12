package log_of_formal_power_series

import "core:c"

MODULUS :: i64(998_244_353)
MAX_N :: 64
MAX_INPUT :: c.size_t(66)

store_le :: proc(output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
log_of_formal_power_series :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT do return -1
    n_value := input[0]
    if n_value < 1 || n_value > i64(MAX_N) do return -1
    n := int(n_value)
    if int(length) != n + 1 do return -1
    for i := 0; i < n; i += 1 {
        if input[i+1] < 0 || input[i+1] >= MODULUS do return -1
    }
    if input[1] != 1 do return -1
    bytes := 8 * n
    if output == nil || int(capacity) < bytes do return -2

    integer_inverse: [MAX_N]i64
    logarithm: [MAX_N]i64
    if n > 1 do integer_inverse[1] = 1
    for k := 2; k < n; k += 1 {
        remainder := int(MODULUS % i64(k))
        integer_inverse[k] = MODULUS - (MODULUS / i64(k)) * integer_inverse[remainder] % MODULUS
    }
    for degree := 1; degree < n; degree += 1 {
        numerator := (i64(degree) * input[degree+1]) % MODULUS
        for i := 1; i < degree; i += 1 {
            term := (i64(i) * logarithm[i]) % MODULUS
            term = term * input[degree-i+1] % MODULUS
            numerator = (numerator - term) % MODULUS
            if numerator < 0 do numerator += MODULUS
        }
        logarithm[degree] = numerator * integer_inverse[degree] % MODULUS
    }
    for i := 0; i < n; i += 1 { store_le(output, 8*i, logarithm[i]) }
    return i64(bytes)
}
