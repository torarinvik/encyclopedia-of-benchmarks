package product_of_polynomial_sequence

import "core:c"

MODULUS :: i64(998_244_353)
MAX_FACTORS :: 6
MAX_COEFFICIENTS :: 25
MAX_INPUT :: c.size_t(38)
MAX_OUTPUT_BYTES :: c.size_t(200)
Polynomial_Buffer :: [MAX_FACTORS * MAX_COEFFICIENTS]i64
Length_Buffer :: [MAX_FACTORS]int

store_le :: proc(output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
product_of_polynomial_sequence :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > MAX_INPUT do return -1
    if input[0] < 0 || input[0] > i64(MAX_FACTORS) do return -1
    count := int(input[0])
    polynomials: Polynomial_Buffer = {}
    poly_lengths: Length_Buffer = {}
    cursor := 1
    degree_sum := 0
    for p := 0; p < count; p += 1 {
        if cursor >= int(length) || input[cursor] < 0 || input[cursor] > 4 do return -1
        degree := int(input[cursor])
        cursor += 1
        if cursor + degree + 1 > int(length) do return -1
        for i := 0; i <= degree; i += 1 {
            coefficient := input[cursor + i]
            if coefficient < 0 || coefficient >= MODULUS do return -1
            polynomials[p * MAX_COEFFICIENTS + i] = coefficient
        }
        if polynomials[p * MAX_COEFFICIENTS + degree] == 0 do return -1
        poly_lengths[p] = degree + 1
        degree_sum += degree
        cursor += degree + 1
    }
    if cursor != int(length) do return -1

    result_length := degree_sum + 1
    bytes := 8 * result_length
    if output == nil || int(capacity) < bytes do return -2
    if count == 0 {
        store_le(output, 0, 1)
        return 8
    }

    scratch: [MAX_COEFFICIENTS]i64 = {}
    active := count
    for active > 1 {
        next_count := 0
        i := 0
        for i < active {
            destination := next_count * MAX_COEFFICIENTS
            if i + 1 == active {
                source := i * MAX_COEFFICIENTS
                for j := 0; j < poly_lengths[i]; j += 1 {
                    polynomials[destination + j] = polynomials[source + j]
                }
                poly_lengths[next_count] = poly_lengths[i]
            } else {
                left_start := i * MAX_COEFFICIENTS
                right_start := (i + 1) * MAX_COEFFICIENTS
                left_length := poly_lengths[i]
                right_length := poly_lengths[i + 1]
                product_length := left_length + right_length - 1
                for j := 0; j < product_length; j += 1 { scratch[j] = 0 }
                for a := 0; a < left_length; a += 1 {
                    for b := 0; b < right_length; b += 1 {
                        slot := a + b
                        scratch[slot] = (scratch[slot] +
                            polynomials[left_start + a] * polynomials[right_start + b]) % MODULUS
                    }
                }
                for j := 0; j < product_length; j += 1 {
                    polynomials[destination + j] = scratch[j]
                }
                poly_lengths[next_count] = product_length
            }
            next_count += 1
            i += 2
        }
        active = next_count
    }
    for i := 0; i < result_length; i += 1 { store_le(output, 8 * i, polynomials[i]) }
    return i64(bytes)
}
