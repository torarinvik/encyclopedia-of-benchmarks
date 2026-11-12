package exp_of_set_power_series

import "core:c"

MODULUS :: i64(998_244_353)
MAX_N :: 5
MAX_SIZE :: 32
MAX_INPUT :: c.size_t(33)

subset_size :: proc "contextless" (mask: int) -> int {
    count := 0
    value := mask
    for value > 0 {
        count += value & 1
        value >>= 1
    }
    return count
}

store_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := transmute(u64)value
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
exp_of_set_power_series :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT do return -1
    if input[0] < 0 || input[0] > i64(MAX_N) do return -1
    n := int(input[0])
    size := 1 << n
    if int(length) != 1 + size || input[1] != 0 do return -1
    for mask := 0; mask < size; mask += 1 {
        if input[1 + mask] < 0 || input[1 + mask] >= MODULUS do return -1
    }

    bytes := 8 * size
    if output == nil || int(capacity) < bytes do return -2

    inverse: [MAX_N + 1]i64
    values: [MAX_SIZE]i64
    if n > 0 do inverse[1] = 1
    for k := 2; k <= n; k += 1 {
        inverse[k] = MODULUS - (MODULUS / i64(k)) * inverse[int(MODULUS % i64(k))] % MODULUS
    }
    values[0] = 1
    for mask := 1; mask < size; mask += 1 {
        total: i64 = 0
        for subset := mask; subset > 0; subset = (subset - 1) & mask {
            term := i64(subset_size(subset)) * input[1 + subset] % MODULUS
            term = term * values[mask ^ subset] % MODULUS
            total = (total + term) % MODULUS
        }
        values[mask] = total * inverse[subset_size(mask)] % MODULUS
    }
    for mask := 0; mask < size; mask += 1 { store_le(output, 8 * mask, values[mask]) }
    return i64(bytes)
}
