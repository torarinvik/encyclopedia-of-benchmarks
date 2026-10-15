package numbers_different_signs

INT32_MIN_VALUE :: i64(-2_147_483_648)
INT32_MAX_VALUE :: i64(2_147_483_647)

// Return whether the signed 32-bit XOR has its sign bit set.
@(export)
numbers_different_signs :: proc "c" (left, right: i64) -> i64 {
    if left < INT32_MIN_VALUE || left > INT32_MAX_VALUE ||
       right < INT32_MIN_VALUE || right > INT32_MAX_VALUE do return -1
    left_value := i32(left)
    right_value := i32(right)
    return if (left_value ~ right_value) < 0 then 1 else 0
}
