package newton_compositional_inverse_fps

import "core:c"

MODULUS :: i64(998_244_353)
Series :: [16]i64

power :: proc(base_value, exponent_value: i64) -> i64 {
    base, exponent, result := base_value, exponent_value, i64(1)
    for exponent > 0 {
        if exponent % 2 != 0 do result = result * base % MODULUS
        base = base * base % MODULUS
        exponent /= 2
    }
    return result
}

multiply :: proc(left, right: Series, width: int) -> Series {
    result: Series
    for i := 0; i < width; i += 1 {
        for j := 0; j < width-i; j += 1 {
            result[i+j] = (result[i+j] + left[i] * right[j]) % MODULUS
        }
    }
    return result
}

compose :: proc(outer, inner: Series, width: int) -> Series {
    result: Series
    degree := width
    for degree > 0 {
        degree -= 1
        result = multiply(result, inner, width)
        result[0] = (result[0] + outer[degree]) % MODULUS
    }
    return result
}

@(export)
newton_compositional_inverse_fps :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 3 || length > 18 do return -1
    if input[0] < 2 || input[0] > 16 do return -1
    n := int(input[0])
    if length != c.size_t(n+1) do return -1
    for i := 0; i < n; i += 1 {
        if input[i+1] < 0 || input[i+1] >= MODULUS do return -1
    }
    if input[1] != 0 || input[2] == 0 do return -1
    bytes := 8*n
    if output == nil || capacity < c.size_t(bytes) do return -2
    f, derivative, inverse: Series
    for i := 0; i < n; i += 1 do f[i] = input[i+1]
    for i := 1; i < n; i += 1 do derivative[i-1] = i64(i) * f[i] % MODULUS
    inverse_linear := power(f[1], MODULUS-2)
    inverse[1] = inverse_linear
    precision := 2
    for precision < n {
        width := min(2*precision, n)
        residual := compose(f, inverse, width)
        residual[1] = (residual[1] + MODULUS - 1) % MODULUS
        slope := compose(derivative, inverse, width)
        reciprocal: Series
        reciprocal[0] = inverse_linear
        for i := 1; i < width; i += 1 {
            sum := i64(0)
            for j := 1; j <= i; j += 1 do sum = (sum + slope[j] * reciprocal[i-j]) % MODULUS
            reciprocal[i] = (MODULUS - sum) * inverse_linear % MODULUS
        }
        correction := multiply(residual, reciprocal, width)
        for i := 0; i < width; i += 1 do inverse[i] = (inverse[i] + MODULUS - correction[i]) % MODULUS
        precision = width
    }
    for i := 0; i < n; i += 1 {
        bits := u64(inverse[i])
        for byte := 0; byte < 8; byte += 1 {
            output[8*i+byte] = u8(bits & 255)
            bits >>= 8
        }
    }
    return i64(bytes)
}
