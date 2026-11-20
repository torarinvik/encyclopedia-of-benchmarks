package aitken_delta_squared_sequence_transform

import "core:c"

MAX_TERMS :: 64
MAX_WORDS :: 66
VALUE_LIMIT :: 1_000_000

aitken_gcd :: proc "contextless" (left_value, right_value: u64) -> u64 {
    left, right := left_value, right_value
    for right != 0 {
        remainder := left % right
        left = right
        right = remainder
    }
    return left
}

aitken_store_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits >> (8 * byte))
    }
}

@(export)
aitken_delta_squared_sequence_transform :: proc "c" (values: [^]i64,
        length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
    if values == nil || length < 3 || length > MAX_WORDS do return -1
    n_value := values[0]
    if n_value < 2 || n_value > MAX_TERMS || length != c.size_t(n_value + 1) do return -1
    n := int(n_value)
    for index := 0; index < n; index += 1 {
        if values[index + 1] < -VALUE_LIMIT || values[index + 1] > VALUE_LIMIT do return -1
    }
    output_length := 16 * (n - 2)
    if output == nil || output_capacity < c.size_t(output_length) do return -2

    for index := 0; index < n - 2; index += 1 {
        first := values[index + 1]
        middle := values[index + 2]
        last := values[index + 3]
        numerator := first * last - middle * middle
        denominator := first - 2 * middle + last
        if denominator == 0 {
            if first == middle && middle == last {
                numerator = first
                denominator = 1
            } else {
                numerator = 0
            }
        } else {
            if denominator < 0 { numerator = -numerator; denominator = -denominator }
            magnitude: u64
            if numerator < 0 {
                magnitude = u64(-numerator)
            } else {
                magnitude = u64(numerator)
            }
            divisor := aitken_gcd(magnitude, u64(denominator))
            numerator /= i64(divisor)
            denominator /= i64(divisor)
        }
        offset := index * 16
        aitken_store_i64(output, offset, numerator)
        aitken_store_i64(output, offset + 8, denominator)
    }
    return i64(output_length)
}
