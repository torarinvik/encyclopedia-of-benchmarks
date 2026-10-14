package gcd_of_n_numbers

import "core:c"

gcd_pair :: proc "contextless" (left_input, right_input: i64) -> i64 {
    left, right := left_input, right_input
    for right != 0 {
        remainder := left % right
        left = right
        right = remainder
    }
    return left
}

@(export)
gcd_of_n_numbers :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length == 0 || length > 64 do return -1
    for index := c.size_t(0); index < length; index += 1 {
        if values[index] < 1 || values[index] > 2147483647 do return -1
    }
    result := values[0]
    for index := c.size_t(1); index < length && result != 1; index += 1 {
        result = gcd_pair(result, values[index])
    }
    return result
}
