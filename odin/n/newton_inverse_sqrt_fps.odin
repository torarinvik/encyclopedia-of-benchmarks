package newton_inverse_sqrt_fps

import "core:c"

MODULUS :: i64(998_244_353)
HALF :: i64(499_122_177)
Series :: [64]i64

multiply :: proc(left, right: Series, width: int) -> Series {
    result: Series
    for i := 0; i < width; i += 1 {
        for j := 0; i + j < width; j += 1 {
            result[i + j] = (result[i + j] + left[i] * right[j]) % MODULUS
        }
    }
    return result
}

@(export)
newton_inverse_sqrt_fps :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 66 do return -1
    if input[0] < 1 || input[0] > 64 do return -1
    n := int(input[0])
    if length != c.size_t(n + 1) do return -1
    for i := 0; i < n; i += 1 {
        if input[i + 1] < 0 || input[i + 1] >= MODULUS do return -1
    }
    if input[1] != 1 do return -1
    bytes := 8 * n
    if output == nil || capacity < c.size_t(bytes) do return -2
    f, inverse: Series
    for i := 0; i < n; i += 1 do f[i] = input[i + 1]
    inverse[0] = 1
    precision := 1
    for precision < n {
        width := min(2 * precision, n)
        square := multiply(inverse, inverse, width)
        product := multiply(f, square, width)
        correction: Series
        correction[0] = (3 + MODULUS - product[0]) * HALF % MODULUS
        for i := 1; i < width; i += 1 do correction[i] = (MODULUS - product[i]) * HALF % MODULUS
        inverse = multiply(inverse, correction, width)
        precision = width
    }
    for i := 0; i < n; i += 1 {
        bits := u64(inverse[i])
        for byte := 0; byte < 8; byte += 1 {
            output[8 * i + byte] = u8(bits & 255)
            bits >>= 8
        }
    }
    return i64(bytes)
}
