package composition_of_formal_power_series

import "core:c"

MODULUS :: i64(998_244_353)
MAX_N :: 16
MAX_INPUT :: c.size_t(34)

store_le :: proc(output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
composition_of_formal_power_series :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 3 || length > MAX_INPUT do return -1
    n_value := input[0]
    if n_value < 1 || n_value > i64(MAX_N) do return -1
    n := int(n_value)
    if int(length) != 1 + 2*n do return -1
    for i := 0; i < 2*n; i += 1 {
        if input[i+1] < 0 || input[i+1] >= MODULUS do return -1
    }
    if input[1+n] != 0 do return -1
    bytes := 8*n
    if output == nil || int(capacity) < bytes do return -2

    composed: [MAX_N]i64 = {}
    for outer := n; outer > 0; outer -= 1 {
        for bound := n; bound > 1; bound -= 1 {
            degree := bound - 1
            sum: i64 = 0
            for inner_degree := 1; inner_degree <= degree; inner_degree += 1 {
                sum = (sum + composed[degree-inner_degree]*input[1+n+inner_degree]) % MODULUS
            }
            composed[degree] = sum
        }
        composed[0] = input[outer]
    }
    for i := 0; i < n; i += 1 { store_le(output, 8*i, composed[i]) }
    return i64(bytes)
}
