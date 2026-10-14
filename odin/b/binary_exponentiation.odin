package binary_exponentiation

import "core:c"

// Exponentiation by squaring with exact signed i64 overflow detection.
@(export)
binary_exponentiation :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length != 2 do return -1
    base_input := values[0]
    exponent_input := values[1]
    if base_input < 0 || base_input > 2147483647 || exponent_input < 0 || exponent_input > 2147483647 do return -1
    base := u64(base_input)
    exponent := u64(exponent_input)
    result := u64(1)
    maximum := u64(9223372036854775807)
    for exponent != 0 {
        if (exponent & 1) != 0 {
            if base != 0 && result > maximum / base do return -1
            result *= base
        }
        exponent >>= 1
        if exponent != 0 {
            if base != 0 && base > maximum / base do return -1
            base *= base
        }
    }
    return i64(result)
}
