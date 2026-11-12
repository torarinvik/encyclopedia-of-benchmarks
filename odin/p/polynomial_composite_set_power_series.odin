package polynomial_composite_set_power_series

import "core:c"

MODULUS :: i64(998_244_353)
MAX_COEFFICIENTS :: 8
MAX_N :: 4
MAX_SIZE :: 16
MAX_INPUT :: c.size_t(27)

store_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := transmute(u64)value
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
polynomial_composite_set_power_series :: proc "c" (
    input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t,
) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT do return -1
    if input[0] < 0 || input[0] > i64(MAX_COEFFICIENTS) ||
        input[1] < 0 || input[1] > i64(MAX_N) do return -1
    count := int(input[0])
    n := int(input[1])
    size := 1 << n
    if int(length) != 2 + count + size do return -1
    for index := 0; index < count + size; index += 1 {
        if input[2 + index] < 0 || input[2 + index] >= MODULUS do return -1
    }

    bytes := 8 * size
    if output == nil || capacity < c.size_t(bytes) do return -2

    series: [MAX_SIZE]i64
    result: [MAX_SIZE]i64
    temporary: [MAX_SIZE]i64
    for mask := 0; mask < size; mask += 1 {
        series[mask] = input[2 + count + mask]
    }

    for degree := count; degree > 0; degree -= 1 {
        for mask := 0; mask < size; mask += 1 {
            total: i64 = 0
            subset := mask
            for {
                total = (total + result[subset] * series[mask ^ subset]) % MODULUS
                if subset == 0 do break
                subset = (subset - 1) & mask
            }
            temporary[mask] = total
        }
        temporary[0] = (temporary[0] + input[1 + degree]) % MODULUS
        for mask := 0; mask < size; mask += 1 {
            result[mask] = temporary[mask]
        }
    }
    for mask := 0; mask < size; mask += 1 {
        store_le(output, 8 * mask, result[mask])
    }
    return i64(bytes)
}
