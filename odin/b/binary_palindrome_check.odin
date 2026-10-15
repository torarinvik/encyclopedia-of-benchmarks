package binary_palindrome_check

@(export)
binary_palindrome_check :: proc "c" (number: i64) -> i64 {
    if number < -2_147_483_648 || number > 2_147_483_647 do return -1
    if number < 0 do return 0
    remaining := number
    reversed := i64(0)
    for remaining > 0 {
        reversed = (reversed << 1) | (remaining & 1)
        remaining >>= 1
    }
    if reversed == number do return 1
    return 0
}
