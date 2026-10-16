package non_repeating_element

import "core:c"

@(export)
non_repeating_element :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length < 2 || length > 64 || length % 2 != 0 do return -1
    xor_result := i32(0)
    for index := c.size_t(0); index < length; index += 1 {
        if values[index] < 0 || values[index] > 1_073_741_823 do return -1
        xor_result ^= i32(values[index])
    }
    rightmost_set_bit := xor_result & -xor_result
    num1 := i32(0)
    num2 := i32(0)
    for index := c.size_t(0); index < length; index += 1 {
        value := i32(values[index])
        if (value & rightmost_set_bit) != 0 do num1 ^= value
        else do num2 ^= value
    }
    return (i64(num1) << 32) | i64(u32(num2))
}
