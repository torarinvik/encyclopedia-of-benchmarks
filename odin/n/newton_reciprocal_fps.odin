package newton_reciprocal_fps

import "core:c"

MODULUS :: i64(998_244_353)

power :: proc(base_value, exponent_value: i64) -> i64 {
    base, exponent, result := base_value, exponent_value, i64(1)
    for exponent > 0 {
        if exponent % 2 != 0 do result = result * base % MODULUS
        base = base * base % MODULUS
        exponent /= 2
    }
    return result
}

@(export)
newton_reciprocal_fps :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 66 do return -1
    if input[0] < 1 || input[0] > 64 do return -1
    n := int(input[0])
    if length != c.size_t(n + 1) do return -1
    for i := 0; i < n; i += 1 {
        if input[i + 1] < 0 || input[i + 1] >= MODULUS do return -1
    }
    if input[1] == 0 do return -1
    bytes := 8 * n
    if output == nil || capacity < c.size_t(bytes) do return -2
    inverse: [64]i64
    inverse[0] = power(input[1], MODULUS - 2)
    precision := 1
    for precision < n {
        width := min(2 * precision, n)
        correction: [64]i64
        for i := 0; i < width; i += 1 {
            for j := 0; j < precision && i + j < width; j += 1 {
                correction[i + j] = (correction[i + j] + input[i + 1] * inverse[j]) % MODULUS
            }
        }
        correction[0] = (2 + MODULUS - correction[0]) % MODULUS
        for i := 1; i < width; i += 1 do correction[i] = (MODULUS - correction[i]) % MODULUS
        next: [64]i64
        for i := 0; i < precision; i += 1 {
            for j := 0; i + j < width; j += 1 {
                next[i + j] = (next[i + j] + inverse[i] * correction[j]) % MODULUS
            }
        }
        inverse = next
        precision = width
    }
    for i := 0; i < n; i += 1 {
        bits := u64(inverse[i])
        for byte := 0; byte < 8; byte += 1 {
            output[8 * i + byte] = u8(bits & 255)
            bits >>= 8
        }
    }
    return i64(bytes)
}
