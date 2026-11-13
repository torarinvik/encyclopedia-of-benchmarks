package prime_modulus_inverse_table

import "core:c"

prime_modulus_inverse_table :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    modulus :: i64(1_000_000_007)
    if input == nil || length < 1 || length > 34 do return -1
    if input[0] < 0 || input[0] > 32 do return -1
    count := int(input[0])
    if length != c.size_t(count + 1) do return -1
    maximum := 0
    for i := 0; i < count; i += 1 {
        if input[i + 1] < 1 || input[i + 1] > 256 do return -1
        maximum = max(maximum, int(input[i + 1]))
    }
    if count == 0 do return 0
    bytes := 4 * count
    if output == nil || capacity < c.size_t(bytes) do return -2
    inverse: [257]i64
    inverse[1] = 1
    for i := 2; i <= maximum; i += 1 {
        value := i64(i)
        inverse[i] = modulus - (modulus / value) * inverse[int(modulus % value)] % modulus
    }
    for i := 0; i < count; i += 1 {
        value := inverse[int(input[i + 1])]
        output[4*i] = u8(value % 256)
        output[4*i+1] = u8((value / 256) % 256)
        output[4*i+2] = u8((value / 65536) % 256)
        output[4*i+3] = u8(value / 16777216)
    }
    return i64(bytes)
}
