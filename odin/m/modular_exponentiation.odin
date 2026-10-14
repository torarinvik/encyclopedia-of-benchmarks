package modular_exponentiation

import "core:c"

// Binary exponentiation under a positive signed 32-bit modulus.
@(export)
modular_exponentiation :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length != 3 do return -1
    base_input := values[0]
    exponent_input := values[1]
    modulus := values[2]
    if base_input < -2147483648 || base_input > 2147483647 || exponent_input < 0 ||
        exponent_input > 2147483647 || modulus < 1 || modulus > 2147483647 {
        return -1
    }
    base := base_input % modulus
    if base < 0 do base += modulus
    exponent := u64(exponent_input)
    result := i64(1) % modulus
    for exponent != 0 {
        if (exponent & 1) != 0 do result = (result * base) % modulus
        base = (base * base) % modulus
        exponent >>= 1
    }
    return result
}
