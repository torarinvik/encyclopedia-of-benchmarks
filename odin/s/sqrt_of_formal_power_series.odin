package sqrt_of_formal_power_series

import "core:c"

MODULUS :: i64(998_244_353)
MAX_N :: 64
MAX_INPUT :: c.size_t(66)

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

mod_sqrt :: proc(value: i64) -> i64 {
    if value == 0 do return 0
    if mod_pow(value, (MODULUS - 1) / 2) != 1 do return -1
    odd_part := MODULUS - 1
    twos := 0
    for odd_part % 2 == 0 { odd_part /= 2; twos += 1 }
    non_residue := i64(2)
    for mod_pow(non_residue, (MODULUS - 1) / 2) != MODULUS - 1 { non_residue += 1 }
    c := mod_pow(non_residue, odd_part)
    root := mod_pow(value, (odd_part + 1) / 2)
    remainder := mod_pow(value, odd_part)
    order := twos
    for remainder != 1 {
        index := 1
        probe := remainder * remainder % MODULUS
        for index < order && probe != 1 { probe = probe * probe % MODULUS; index += 1 }
        if index >= order || probe != 1 do return -1
        exponent := i64(1)
        for bit := 0; bit < order-index-1; bit += 1 { exponent *= 2 }
        factor := mod_pow(c, exponent)
        root = root * factor % MODULUS
        factor_squared := factor * factor % MODULUS
        remainder = remainder * factor_squared % MODULUS
        c = factor_squared
        order = index
    }
    return min(root, MODULUS - root)
}

store_le :: proc(output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
sqrt_of_formal_power_series :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT do return -1
    if input[0] < 1 || input[0] > i64(MAX_N) do return -1
    n := int(input[0])
    if int(length) != n + 1 do return -1
    for i := 0; i < n; i += 1 { if input[i+1] < 0 || input[i+1] >= MODULUS do return -1 }
    bytes := 8 * n
    if output == nil || int(capacity) < bytes do return -2

    result: [MAX_N]i64
    valuation := 0
    for valuation < n && input[valuation+1] == 0 { valuation += 1 }
    if valuation == n {
        for i := 0; i < n; i += 1 { store_le(output, 8*i, 0) }
        return i64(bytes)
    }
    if valuation % 2 != 0 { store_le(output, 0, -1); return 8 }
    shift := valuation / 2
    leading_root := mod_sqrt(input[valuation+1])
    if leading_root < 0 { store_le(output, 0, -1); return 8 }
    inverse_twice_root := mod_pow((2 * leading_root) % MODULUS, MODULUS - 2)
    width := n - valuation
    result[shift] = leading_root
    for degree := 1; degree < width; degree += 1 {
        cross_terms := i64(0)
        for i := 1; i < degree; i += 1 {
            cross_terms = (cross_terms + result[shift+i] * result[shift+degree-i]) % MODULUS
        }
        delta := (input[valuation+degree+1] - cross_terms) % MODULUS
        if delta < 0 do delta += MODULUS
        result[shift+degree] = delta * inverse_twice_root % MODULUS
    }
    for i := 0; i < n; i += 1 { store_le(output, 8*i, result[i]) }
    return i64(bytes)
}
