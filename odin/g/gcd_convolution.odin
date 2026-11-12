package gcd_convolution

import "core:c"

MAX_N :: 128
MAX_INPUT_LENGTH :: 1 + 2*MAX_N + 1
MODULUS :: i64(998244353)

store_i64_le :: proc "contextless" (output: [^]u8, offset: c.size_t, value: i64) {
    bits := u64(value)
    for byte := c.size_t(0); byte < 8; byte += 1 {
        output[offset + byte] = u8(bits & 255)
        bits >>= 8
    }
}

divisor_zeta :: proc(values: ^[MAX_N + 1]i64, n: int) {
    for divisor := 1; divisor <= n; divisor += 1 {
        for multiple := 2*divisor; multiple <= n; multiple += divisor {
            values[divisor] += values[multiple]
            if values[divisor] >= MODULUS { values[divisor] -= MODULUS }
        }
    }
}

divisor_mobius :: proc(values: ^[MAX_N + 1]i64, n: int) {
    for divisor := n; divisor >= 1; divisor -= 1 {
        for multiple := 2*divisor; multiple <= n; multiple += divisor {
            values[divisor] -= values[multiple]
            if values[divisor] < 0 { values[divisor] += MODULUS }
        }
    }
}

@(export)
gcd_convolution :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH) { return -1 }
    n_value := input[0]
    if n_value < 1 || n_value > MAX_N { return -1 }
    n := int(n_value)
    if length != c.size_t(1 + 2*n) { return -1 }
    for index := 0; index < 2*n; index += 1 {
        value := input[1 + index]
        if value < 0 || value >= MODULUS { return -1 }
    }
    output_bytes := 8*n
    if output == nil || capacity < c.size_t(output_bytes) { return -2 }

    a: [MAX_N + 1]i64
    b: [MAX_N + 1]i64
    c_values: [MAX_N + 1]i64
    for index := 0; index <= MAX_N; index += 1 {
        a[index] = 0
        b[index] = 0
        c_values[index] = 0
    }
    for index := 1; index <= n; index += 1 {
        a[index] = input[index]
        b[index] = input[n + index]
    }
    divisor_zeta(&a, n)
    divisor_zeta(&b, n)
    for index := 1; index <= n; index += 1 do c_values[index] = (a[index] * b[index]) % MODULUS
    divisor_mobius(&c_values, n)
    for index := 1; index <= n; index += 1 {
        store_i64_le(output, c.size_t(8*(index-1)), c_values[index])
    }
    return i64(output_bytes)
}
