package power_projection_of_set_power_series

import "core:c"

MODULUS :: i64(998_244_353)
MAX_N :: 4
MAX_M :: 8
MAX_SIZE :: 16
MAX_INPUT :: c.size_t(35)

store_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := transmute(u64)value
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
power_projection_of_set_power_series :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT do return -1
    if input[0] < 0 || input[0] > i64(MAX_N) || input[1] < 0 || input[1] > i64(MAX_M) do return -1
    n := int(input[0])
    powers := int(input[1])
    size := 1 << n
    if int(length) != 2 + 2 * size do return -1

    series: [MAX_SIZE]i64
    weights: [MAX_SIZE]i64
    for mask := 0; mask < size; mask += 1 {
        a := input[2 + mask]
        w := input[2 + size + mask]
        if a < 0 || a >= MODULUS || w < 0 || w >= MODULUS do return -1
        series[mask] = a
        weights[mask] = w
    }

    bytes := 8 * powers
    if output == nil || int(capacity) < bytes do return -2

    current: [MAX_SIZE]i64
    next: [MAX_SIZE]i64
    current[0] = 1
    for power := 0; power < powers; power += 1 {
        projection: i64 = 0
        for mask := 0; mask < size; mask += 1 {
            projection = (projection + weights[mask] * current[mask]) % MODULUS
        }
        store_le(output, 8 * power, projection)
        if power + 1 == powers do break
        for mask := 0; mask < size; mask += 1 {
            total: i64 = 0
            subset := mask
            for {
                total = (total + current[subset] * series[mask ^ subset]) % MODULUS
                if subset == 0 do break
                subset = (subset - 1) & mask
            }
            next[mask] = total
        }
        for mask := 0; mask < size; mask += 1 { current[mask] = next[mask] }
    }
    return i64(bytes)
}
