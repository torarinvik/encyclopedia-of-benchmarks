package compositional_inverse_of_formal_power_series

import "core:c"

MODULUS :: i64(998_244_353)
MIN_N :: 2
MAX_N :: 16
MAX_INPUT :: c.size_t(18)

mod_pow :: proc(base_value, exponent_value: i64) -> i64 {
    base := base_value % MODULUS
    exponent := exponent_value
    result := i64(1)
    for exponent > 0 {
        if exponent % 2 != 0 do result = result * base % MODULUS
        base = base * base % MODULUS
        exponent /= 2
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
compositional_inverse_of_formal_power_series :: proc "c" (input: [^]i64,
    length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < c.size_t(MIN_N + 1) || length > MAX_INPUT do return -1
    if input[0] < i64(MIN_N) || input[0] > i64(MAX_N) do return -1
    n := int(input[0])
    if int(length) != n + 1 do return -1
    for i := 0; i < n; i += 1 { if input[i+1] < 0 || input[i+1] >= MODULUS do return -1 }
    if input[1] != 0 || input[2] == 0 do return -1
    bytes := 8 * n
    if output == nil || int(capacity) < bytes do return -2

    powers: [MAX_N * MAX_N]i64
    inverse_series: [MAX_N]i64
    inverse_linear := mod_pow(input[2], MODULUS - 2)
    inverse_series[1] = inverse_linear
    powers[MAX_N + 1] = inverse_linear
    for degree := 2; degree < n; degree += 1 {
        for power := 2; power <= degree; power += 1 {
            coefficient := i64(0)
            for split := 1; split < degree; split += 1 {
                coefficient = (coefficient + powers[(power-1)*MAX_N+degree-split] *
                    inverse_series[split]) % MODULUS
            }
            powers[power*MAX_N+degree] = coefficient
        }
        composed_coefficient := i64(0)
        for power := 2; power <= degree; power += 1 {
            composed_coefficient = (composed_coefficient + input[power+1] *
                powers[power*MAX_N+degree]) % MODULUS
        }
        inverse_series[degree] = (MODULUS - composed_coefficient) * inverse_linear % MODULUS
        powers[MAX_N+degree] = inverse_series[degree]
    }
    for i := 0; i < n; i += 1 { store_le(output, 8*i, inverse_series[i]) }
    return i64(bytes)
}
