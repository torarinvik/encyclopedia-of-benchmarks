package division_of_polynomials

import "core:c"

MODULUS :: i64(998_244_353)
MAX_N :: 64
MAX_INPUT :: c.size_t(131)
MAX_OUTPUT_BYTES :: c.size_t(536)
Poly :: [MAX_N]i64

power_mod :: proc(base_input, exponent_input: i64) -> i64 {
    base, exponent, result := base_input, exponent_input, i64(1)
    for exponent > 0 {
        if (exponent & 1) != 0 do result = result * base % MODULUS
        base = base * base % MODULUS
        exponent >>= 1
    }
    return result
}

trim :: proc(poly: Poly, length_input: int) -> int {
    length := length_input
    for length > 0 && poly[length - 1] == 0 { length -= 1 }
    return length
}

store_le :: proc(output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
division_of_polynomials :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 4 || length > MAX_INPUT do return -1
    if input[0] < 1 || input[0] > i64(MAX_N) || input[1] < 1 || input[1] > i64(MAX_N) do return -1
    n, m := int(input[0]), int(input[1])
    if int(length) != 2 + n + m do return -1

    work, quotient := Poly{}, Poly{}
    for i := 0; i < n; i += 1 {
        work[i] = input[2 + i]
        if work[i] < 0 || work[i] >= MODULUS do return -1
    }
    for i := 0; i < m; i += 1 {
        coefficient := input[2 + n + i]
        if coefficient < 0 || coefficient >= MODULUS do return -1
    }
    if work[n - 1] == 0 || input[2 + n + m - 1] == 0 do return -1

    quotient_bound := 0
    if n >= m {
        quotient_bound = n - m + 1
        inverse_leading := power_mod(input[2 + n + m - 1], MODULUS - 2)
        shift_plus_one := quotient_bound
        for shift_plus_one > 0 {
            shift := shift_plus_one - 1
            factor := work[shift + m - 1] * inverse_leading % MODULUS
            quotient[shift] = factor
            for j := 0; j < m; j += 1 {
                value := (work[shift + j] - factor * input[2 + n + j]) % MODULUS
                if value < 0 do value += MODULUS
                work[shift + j] = value
            }
            shift_plus_one -= 1
        }
    }

    quotient_length := trim(quotient, quotient_bound)
    remainder_bound := min(n, m)
    remainder_length := trim(work, remainder_bound)
    bytes := 8 * (2 + quotient_length + remainder_length)
    if bytes > int(MAX_OUTPUT_BYTES) do return -1
    if output == nil || int(capacity) < bytes do return -2

    store_le(output, 0, i64(quotient_length))
    store_le(output, 8, i64(remainder_length))
    offset := 16
    for i := 0; i < quotient_length; i += 1 {
        store_le(output, offset, quotient[i])
        offset += 8
    }
    for i := 0; i < remainder_length; i += 1 {
        store_le(output, offset, work[i])
        offset += 8
    }
    return i64(bytes)
}
